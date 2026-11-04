import CoreBluetooth
import Foundation
import Domain

/// Why a Bluetooth heart-rate stream ended.
public enum BluetoothHeartRateError: Error, Equatable, Sendable {
    /// The user denied Bluetooth access for the app.
    case unauthorized
    /// Bluetooth is switched off on this device.
    case poweredOff
    /// This device has no Bluetooth Low Energy.
    case unsupported
    /// Connecting to the monitor failed.
    case connectionFailed
    /// The monitor disconnected (out of range, battery, strap removed).
    case disconnected
}

/// A real heart-rate monitor over Bluetooth Low Energy: any chest strap or watch that offers the
/// standard Heart Rate service (0x180D).
///
/// Each call to `readings()` scans for the nearest monitor, connects, and streams its readings.
/// Cancelling the stream disconnects. Choosing between several monitors comes later; for now
/// it connects to the first one it finds.
public struct BluetoothHeartRateSource: HeartRateSource {
    public init() {}

    public func readings() -> AsyncThrowingStream<HeartRateSample, any Error> {
        let (stream, continuation) = AsyncThrowingStream.makeStream(of: HeartRateSample.self)
        // The session owns the radio. Capturing it in `onTermination` keeps it alive exactly as
        // long as the stream, and `stop()` tears the connection down when the stream ends.
        let session = Session(continuation: continuation)
        continuation.onTermination = { _ in session.stop() }
        session.start()
        return stream
    }
}

// MARK: - Session

extension BluetoothHeartRateSource {
    /// One scan → connect → subscribe run.
    ///
    /// CoreBluetooth reports through delegate callbacks, all delivered on `queue`. Every property
    /// is touched only on that queue, which is why `@unchecked Sendable` is safe here.
    private final class Session: NSObject, @unchecked Sendable, CBCentralManagerDelegate, CBPeripheralDelegate {
        private let heartRateService = CBUUID(string: "180D")
        private let heartRateMeasurement = CBUUID(string: "2A37")

        private let queue = DispatchQueue(label: "FitTracker.BluetoothHeartRateSource")
        private let continuation: AsyncThrowingStream<HeartRateSample, any Error>.Continuation
        private var central: CBCentralManager?
        private var peripheral: CBPeripheral?   // strong reference: CoreBluetooth doesn't keep it alive
        private var isFinished = false

        init(continuation: AsyncThrowingStream<HeartRateSample, any Error>.Continuation) {
            self.continuation = continuation
        }

        func start() {
            queue.async {
                // Creating the manager triggers the permission prompt the first time.
                self.central = CBCentralManager(delegate: self, queue: self.queue)
            }
        }

        func stop() {
            queue.async {
                self.isFinished = true
                self.central?.stopScan()
                if let peripheral = self.peripheral {
                    self.central?.cancelPeripheralConnection(peripheral)
                }
                self.peripheral = nil
                self.central = nil
            }
        }

        /// Ends the stream once. `error == nil` is a normal finish.
        private func finish(with error: BluetoothHeartRateError?) {
            guard !isFinished else { return }
            isFinished = true
            continuation.finish(throwing: error)
        }

        // MARK: CBCentralManagerDelegate

        func centralManagerDidUpdateState(_ central: CBCentralManager) {
            switch central.state {
            case .poweredOn:
                central.scanForPeripherals(withServices: [heartRateService])
            case .unauthorized: finish(with: .unauthorized)
            case .poweredOff: finish(with: .poweredOff)
            case .unsupported: finish(with: .unsupported)
            case .resetting, .unknown: break   // a new state arrives shortly
            @unknown default: break
            }
        }

        func centralManager(
            _ central: CBCentralManager,
            didDiscover peripheral: CBPeripheral,
            advertisementData: [String: Any],
            rssi RSSI: NSNumber
        ) {
            // First monitor found wins. Stop scanning so a second one isn't also connected.
            central.stopScan()
            self.peripheral = peripheral
            peripheral.delegate = self
            central.connect(peripheral)
        }

        func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
            peripheral.discoverServices([heartRateService])
        }

        func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: (any Error)?) {
            finish(with: .connectionFailed)
        }

        func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: (any Error)?) {
            finish(with: .disconnected)
        }

        // MARK: CBPeripheralDelegate

        func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: (any Error)?) {
            guard error == nil, let service = peripheral.services?.first(where: { $0.uuid == heartRateService }) else {
                return finish(with: .connectionFailed)
            }
            peripheral.discoverCharacteristics([heartRateMeasurement], for: service)
        }

        func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: (any Error)?) {
            guard error == nil, let characteristic = service.characteristics?.first(where: { $0.uuid == heartRateMeasurement }) else {
                return finish(with: .connectionFailed)
            }
            // Ask the monitor to push a notification for every new reading.
            peripheral.setNotifyValue(true, for: characteristic)
        }

        func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: (any Error)?) {
            guard error == nil, let data = characteristic.value else { return }
            // A malformed packet or lost skin contact is skipped; the next notification follows in about a second.
            if let measurement = try? HeartRateMeasurement(data: data),
               let sample = try? measurement.sample(at: .now) {
                continuation.yield(sample)
            }
        }
    }
}

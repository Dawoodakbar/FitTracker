/// The plans that ship with the app.
///
/// These are general fitness routines, not medical advice. Plan ids and session ids are
/// stored in `PlanProgress`, so never change one that has shipped.
public enum PlanCatalog {
    public static let all: [WorkoutPlan] = [
        homeStrength, gymFullBody, morningYoga, sleepYoga, hiit, firstFiveK, deskMobility
    ]

    public static func plan(id: String) -> WorkoutPlan? {
        all.first { $0.id == id }
    }

    // MARK: - Strength

    static let homeStrength = WorkoutPlan(
        id: "home-strength",
        title: "Home Strength Basics",
        summary: "Build a base with bodyweight moves. No equipment, about 20 minutes.",
        kind: .strength, level: .beginner, equipment: .none, weeks: 4,
        sessions: [
            PlanSession(id: "a", title: "Lower body + core", exercises: [
                Exercise("Bodyweight squat", .reps(sets: 3, reps: 12), rest: 45, cue: "Sit back, knees over toes, chest up."),
                Exercise("Reverse lunge", .reps(sets: 3, reps: 10), rest: 45, cue: "Step back, lower until both knees bend 90°."),
                Exercise("Glute bridge", .reps(sets: 3, reps: 15), rest: 30, cue: "Squeeze at the top, ribs down."),
                Exercise("Plank", .timed(rounds: 3, seconds: 30), rest: 30, cue: "Straight line from head to heels.")
            ]),
            PlanSession(id: "b", title: "Upper body + core", exercises: [
                Exercise("Incline push-up", .reps(sets: 3, reps: 10), rest: 45, cue: "Hands on a chair or counter, body straight."),
                Exercise("Table row", .reps(sets: 3, reps: 8), rest: 45, cue: "Pull your chest to the edge, squeeze shoulder blades."),
                Exercise("Pike shoulder tap", .reps(sets: 3, reps: 12), rest: 30, cue: "Hips high, tap opposite shoulder slowly."),
                Exercise("Dead bug", .reps(sets: 3, reps: 10), rest: 30, cue: "Lower back stays pressed into the floor.")
            ])
        ]
    )

    static let gymFullBody = WorkoutPlan(
        id: "gym-full-body",
        title: "Gym Full Body 3×",
        summary: "Three full-body days built on the big lifts. Add weight when all sets feel easy.",
        kind: .strength, level: .intermediate, equipment: .gym, weeks: 6,
        sessions: [
            PlanSession(id: "a", title: "Squat focus", exercises: [
                Exercise("Back squat", .reps(sets: 4, reps: 6), rest: 120, cue: "Brace, break at hips and knees together."),
                Exercise("Bench press", .reps(sets: 3, reps: 8), rest: 90, cue: "Shoulder blades pinned, bar to mid-chest."),
                Exercise("Lat pulldown", .reps(sets: 3, reps: 10), rest: 60, cue: "Pull elbows to your sides, no swinging."),
                Exercise("Hanging knee raise", .reps(sets: 3, reps: 12), rest: 45, cue: "Curl hips up, lower with control.")
            ]),
            PlanSession(id: "b", title: "Hinge focus", exercises: [
                Exercise("Romanian deadlift", .reps(sets: 4, reps: 8), rest: 120, cue: "Push hips back, bar close to legs."),
                Exercise("Overhead press", .reps(sets: 3, reps: 8), rest: 90, cue: "Squeeze glutes, press in a straight line."),
                Exercise("Seated cable row", .reps(sets: 3, reps: 10), rest: 60, cue: "Tall chest, pull to your belly button."),
                Exercise("Farmer carry", .timed(rounds: 3, seconds: 40), rest: 60, cue: "Shoulders back, short quick steps.")
            ]),
            PlanSession(id: "c", title: "Single leg + push", exercises: [
                Exercise("Bulgarian split squat", .reps(sets: 3, reps: 8), rest: 90, cue: "Front foot far enough that the knee stays behind toes."),
                Exercise("Incline dumbbell press", .reps(sets: 3, reps: 10), rest: 75, cue: "Elbows at 45°, full stretch at the bottom."),
                Exercise("Pull-up or assisted pull-up", .reps(sets: 3, reps: 6), rest: 90, cue: "Start from a dead hang, chin over the bar."),
                Exercise("Cable face pull", .reps(sets: 3, reps: 15), rest: 45, cue: "Pull to your forehead, elbows high.")
            ])
        ]
    )

    // MARK: - Yoga

    static let morningYoga = WorkoutPlan(
        id: "morning-yoga",
        title: "Morning Yoga Flow",
        summary: "A gentle 10-minute flow to wake up your spine, hips and shoulders.",
        kind: .yoga, level: .beginner, equipment: .none, weeks: 2,
        sessions: [
            PlanSession(id: "flow", title: "Wake-up flow", exercises: [
                Exercise("Cat-cow", .timed(rounds: 1, seconds: 60), cue: "Inhale to arch, exhale to round."),
                Exercise("Downward dog", .timed(rounds: 2, seconds: 45), cue: "Hips up and back, bend knees if hamstrings are tight."),
                Exercise("Low lunge", .timed(rounds: 2, seconds: 45), cue: "One round each side. Sink hips, lift chest."),
                Exercise("Cobra", .timed(rounds: 2, seconds: 30), cue: "Elbows close, lift with your back, not your arms."),
                Exercise("Child's pose", .timed(rounds: 1, seconds: 60), cue: "Forehead down, breathe into your back.")
            ])
        ]
    )

    static let sleepYoga = WorkoutPlan(
        id: "sleep-yoga",
        title: "Wind-Down Yoga",
        summary: "Slow stretches and long exhales to do right before bed.",
        kind: .yoga, level: .beginner, equipment: .none, weeks: 2,
        sessions: [
            PlanSession(id: "wind-down", title: "Bedtime stretch", exercises: [
                Exercise("Seated forward fold", .timed(rounds: 1, seconds: 90), cue: "Fold from the hips, let your head hang."),
                Exercise("Supine twist", .timed(rounds: 2, seconds: 60), cue: "One round each side. Both shoulders stay down."),
                Exercise("Legs up the wall", .timed(rounds: 1, seconds: 120), cue: "Hips close to the wall, arms relaxed."),
                Exercise("Box breathing", .timed(rounds: 1, seconds: 120), cue: "In 4, hold 4, out 4, hold 4.")
            ])
        ]
    )

    // MARK: - Cardio

    static let hiit = WorkoutPlan(
        id: "hiit-20",
        title: "HIIT 20",
        summary: "Short, hard intervals: 30 seconds on, 30 off. Done in 20 minutes.",
        kind: .hiit, level: .intermediate, equipment: .none, weeks: 4,
        sessions: [
            PlanSession(id: "a", title: "Full-body burner", exercises: [
                Exercise("Jumping jack", .timed(rounds: 4, seconds: 30), rest: 30, cue: "Land softly, keep a steady rhythm."),
                Exercise("Squat jump", .timed(rounds: 4, seconds: 30), rest: 30, cue: "Explode up, land quietly into the next squat."),
                Exercise("Mountain climber", .timed(rounds: 4, seconds: 30), rest: 30, cue: "Hips level, drive knees fast."),
                Exercise("Burpee", .timed(rounds: 4, seconds: 30), rest: 30, cue: "Chest to floor, jump and reach."),
                Exercise("High knees", .timed(rounds: 4, seconds: 30), rest: 30, cue: "Knees to hip height, pump your arms.")
            ])
        ]
    )

    static let firstFiveK = WorkoutPlan(
        id: "first-5k",
        title: "First 5K",
        summary: "Run-walk intervals three times a week, building to 30 minutes of running.",
        kind: .running, level: .beginner, equipment: .none, weeks: 8,
        sessions: [
            PlanSession(id: "intervals", title: "Run-walk intervals", exercises: [
                Exercise("Brisk walk warm-up", .timed(rounds: 1, seconds: 300), cue: "Easy pace, loosen up."),
                Exercise("Easy run", .timed(rounds: 6, seconds: 90), rest: 90, cue: "Slow enough to talk. Walk during the rest."),
                Exercise("Cool-down walk", .timed(rounds: 1, seconds: 300), cue: "Let your heart rate come down.")
            ]),
            PlanSession(id: "steady", title: "Steady effort", exercises: [
                Exercise("Brisk walk warm-up", .timed(rounds: 1, seconds: 300), cue: "Easy pace, loosen up."),
                Exercise("Easy run", .timed(rounds: 3, seconds: 300), rest: 120, cue: "Zone 2 to 3. Walk during the rest."),
                Exercise("Cool-down walk", .timed(rounds: 1, seconds: 300), cue: "Let your heart rate come down.")
            ])
        ]
    )

    // MARK: - Mobility

    static let deskMobility = WorkoutPlan(
        id: "desk-mobility",
        title: "Desk Reset",
        summary: "Five minutes to undo sitting: neck, chest, hips and upper back.",
        kind: .mobility, level: .beginner, equipment: .none, weeks: 2,
        sessions: [
            PlanSession(id: "reset", title: "5-minute reset", exercises: [
                Exercise("Neck circle", .timed(rounds: 1, seconds: 45), cue: "Slow half circles, shoulders relaxed."),
                Exercise("Doorway chest stretch", .timed(rounds: 2, seconds: 30), cue: "Forearm on the frame, turn away gently."),
                Exercise("Thoracic rotation", .timed(rounds: 2, seconds: 30), cue: "One round each side. Follow your hand with your eyes."),
                Exercise("Hip flexor stretch", .timed(rounds: 2, seconds: 40), cue: "One round each side. Tuck your tailbone."),
                Exercise("Standing forward fold", .timed(rounds: 1, seconds: 45), cue: "Soft knees, let your arms hang.")
            ])
        ]
    )
}

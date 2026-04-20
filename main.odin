package pendulum

import "core:fmt"
import "core:math"
import "core:math/rand"
import "core:math/linalg"

import rl "vendor:raylib"

Vec2 :: rl.Vector2

BACKGROUND :: rl.Color{0x30, 0x30, 0x30, 0xff}
PIVOT_COLOR :: rl.PURPLE
BALL_COLOR :: rl.Color{0xff, 0x30, 0x30, 0xff}

GRAVITY := Vec2{ 0, 980, }
ROD_INITIAL_LENGTH :: 200.0
ROD_THICK :: 8.0
BALL_RADIUS :: 50.0

main :: proc() {
    rl.InitWindow(800, 600, "Pendulum")
    rl.SetTargetFPS(rl.GetMonitorRefreshRate(0))
    defer rl.CloseWindow()

    pivot_pos := Vec2{400, 200}
    rod_length: f32 = ROD_INITIAL_LENGTH
    ball_pos := pivot_pos + Vec2{ 0, rod_length }
    ball_vel: Vec2

    ball_held := false
    hold_delta: Vec2
    for !rl.WindowShouldClose() {
        dt := rl.GetFrameTime()
        mouse_pos := rl.GetMousePosition()
        if ball_held {
            ball_pos = mouse_pos + hold_delta
            if rl.IsMouseButtonReleased(.LEFT) {
                ball_held = false
                rod_length = linalg.distance(ball_pos, pivot_pos)
                delta := 0.5*rl.GetMouseDelta()
                ball_vel = delta / dt
            }
        } else if rl.CheckCollisionPointCircle(mouse_pos, ball_pos, BALL_RADIUS) {
            if rl.IsMouseButtonPressed(.LEFT) {
                ball_held = true
                hold_delta = ball_pos - mouse_pos
            }
        }

        // simulate
        substeps := 10
        dt /= f32(substeps)
        for _ in 0..<substeps {
            if !ball_held {
                prev_pos := ball_pos

                // gravity
                ball_vel += GRAVITY * dt
                ball_pos += ball_vel * dt

                // rod constraint
                diff := pivot_pos - ball_pos
                distance := math.sqrt(linalg.dot(diff, diff))
                dir := linalg.normalize(diff)
                correction := distance - rod_length
                ball_pos += dir * correction

                if dt > 0 {
                    ball_vel = (ball_pos - prev_pos) / dt
                }
            }
        }

        rl.BeginDrawing()
        rl.ClearBackground(BACKGROUND)

        rl.DrawLineEx(pivot_pos, ball_pos, ROD_THICK, rl.RAYWHITE)
        rl.DrawCircleV(pivot_pos, 30, PIVOT_COLOR)
        rl.DrawCircleV(ball_pos, BALL_RADIUS, BALL_COLOR)
        rl.DrawText(rl.TextFormat("%8.2f", ball_vel), 10, 10, 20, rl.RAYWHITE)
        rl.EndDrawing()
    }
}

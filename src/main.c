#include <raylib.h>

int main(void) {
    // Initialization
    const int screenWidth = 800;
    const int screenHeight = 450;

    InitWindow(screenWidth, screenHeight, "Hello Raylib");

    // Main game loop
    while (!WindowShouldClose()) {
        // Update
        // TODO: Your game logic goes here

        // Draw
        BeginDrawing();
        ClearBackground(RAYWHITE);
        DrawText("Hello, Raylib!", 10, 10, 20, DARKGRAY);
        EndDrawing();
    }

    // De-Initialization
    CloseWindow();

    return 0;
}
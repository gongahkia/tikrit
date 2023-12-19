// FUA 

    // immediate
        // continue learning raylib
        // implement global struct to store data and states
        // write a serialization library to serialize data to json or txt files
        // import other header files of F#-like functions

    // 2 implement
        // add in sprites

// ---------- header files -----------

#include <raylib.h>

int main(void) {

// ---------- initalization ---------- 

    const int screenWidth = 800;
    const int screenHeight = 450;

    InitWindow(screenWidth, screenHeight, "Tikrit");

// ---------- presets ----------

    const char titleText[13] = "Welc 2 Tikrit";
    const int titleFontSize = 40;
    int titleFontWidth = MeasureText(titleText, titleFontSize);
    int titleFontHeight = titleFontSize;
    int titleFontX = (screenWidth - titleFontWidth) / 2; // to help draw text in middle of screen
    int titleFontY = (screenHeight - titleFontHeight) / 2;

// ---------- main game loop -----------

    while (!WindowShouldClose()) {

        // drawing to screen
        BeginDrawing();
        ClearBackground(RAYWHITE);
        DrawText(titleText, titleFontX, titleFontY, titleFontSize, DARKGRAY);
        EndDrawing();

    }

// ---------- de-initialization ----------

    CloseWindow();

    return 0;
}
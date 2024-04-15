# The Workout Tracking Feature

This Python program allows for the real-time tracking of workouts

## Environment Information

The program currently runs with Python 3.8. The dependencies required are as follows:
- Opencv-python (pip install opencv-python)
- MediaPipe (pip install mediapipe)
- sv-ttk (pip istall sv-ttk)
- Pillow (pip install pillow)
- pyinstaller (pip install pyinstaller)

## Workouts Currently Support

- Curls (1)
- Squats (2)

## How to Build

The following command can be run in the Workout_Tracker.py directory to build the Workout Tracking feature
- pyinstaller --noconfirm --onedir --windowed --hidden-import tkinter --hidden-import sv_ttk Workout_Tracker.py
The resulting executable can be found at dist\Workout_Tracker\Workout_Tracker.exe

## How to Run

With the absolute path run the following
- &"[absolute path]" [workout value]
- The absolute path is the absolute file location
- The workout value is the value of the workout to track (currently can be 1 or 2)
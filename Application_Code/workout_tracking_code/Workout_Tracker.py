import sys
import cv2
import math
import mediapipe as mp
from mediapipe.python.solutions.pose import PoseLandmark
from tkinter import *
import sv_ttk
from PIL import Image, ImageTk
from pathlib import Path
import time

# Mediapipe
mpDraw = mp.solutions.drawing_utils
mpPose = mp.solutions.pose
pose = mpPose.Pose()

# Main application
class App:
    def __init__(self, videoSource = 0, workoutType = 1):
        # Setup application
        self.appName = 'Workout Tracker'
        self.window = Tk()
        self.window.title(self.appName)
        self.window.resizable(0, 0)
        self.window.iconbitmap(default = str(Path.cwd()) + '/blank.ico')
        self.backgroundColor = 'white'
        self.fontColor = 'blue'
        self.window['bg'] = self.backgroundColor
        self.videoSource = videoSource
        sv_ttk.set_theme("dark")
        self.capture = workoutTracker(self.videoSource)

        # Initialize workout tracking information
        self.workoutType = workoutType
        self.timer = 0
        self.title = ''
        self.repetitionsCount = [0] # if there is a left and right count left will be 0 and right will be 1
        self.previousAngle = [180] # if there is a left and right angle left will be 0 and right will be 1
        self.showLandmarksList = []

        # Update values base on workout type
        if self.workoutType == 1:
            self.title = 'Curl'
            self.repetitionsCount.append(0)
            self.previousAngle.append(0)
            self.showLandmarksList = [PoseLandmark.LEFT_SHOULDER, PoseLandmark.RIGHT_SHOULDER, PoseLandmark.LEFT_ELBOW, PoseLandmark.RIGHT_ELBOW, PoseLandmark.LEFT_WRIST, PoseLandmark.RIGHT_WRIST]
        elif self.workoutType == 2:
            self.title = 'Squat'
            self.previousAngle.append(0)
            self.showLandmarksList = [PoseLandmark.LEFT_HIP, PoseLandmark.RIGHT_HIP, PoseLandmark.LEFT_KNEE, PoseLandmark.RIGHT_KNEE, PoseLandmark.LEFT_ANKLE, PoseLandmark.RIGHT_ANKLE]
        self.customConnection = self.capture.createLandmarkConnectionList(self.showLandmarksList)

        # Header
        self.header = Label(self.window, text = (self.title + ' Tracker'), font = 25, fg = self.fontColor, bg = self.backgroundColor)
        self.header.grid(row = 0, column = 0, columnspan = 3)

        # Left side counter
        self.leftCounter = Label(self.window, text = '', font = 12, fg = self.fontColor, bg = self.backgroundColor)
        self.leftCounter.grid(row = 1, column = 0, sticky = 'NEW')

        # Total side counter
        self.totalCounter = Label(self.window, text = '', font = 12, fg = self.fontColor, bg = self.backgroundColor)
        self.totalCounter.grid(row = 1, column = 1, sticky = 'NEW')

        # Right side counter
        self.rightCounter = Label(self.window, '', font = 12, fg = self.fontColor, bg = self.backgroundColor)
        self.rightCounter.grid(row = 1, column = 2, sticky = 'NEW')

        # Video
        self.canvas = Canvas(self.window, width = self.capture.width, height = self.capture.height, borderwidth = 0)
        self.canvas.grid(row = 2, column = 0, columnspan = 3, padx = 10)

        # Button for closing 
        self.btn_done = Button(self.window, text = "Done", command = self.Close, font = 12, fg = self.backgroundColor, bg = self.fontColor) 
        self.btn_done.grid(row = 3, column = 0, columnspan = 3, pady = 10)

        # Update and run app
        self.update()
        self.window.mainloop()

    def update(self):
        # Get landmarks and act accordingly
        frame, frameRGB = self.capture.getFrame()
        results = pose.process(frameRGB)
        if results.pose_landmarks:

            # Track the specific workout
            if self.workoutType == 1:
                self.capture.trackCurls(results.pose_landmarks, self.repetitionsCount, self.previousAngle)
            elif self.workoutType == 2:
               self.capture.trackSquats(results.pose_landmarks, self.repetitionsCount, self.previousAngle)

            # Draw landmarks and show the visibility of each point
            mpDraw.draw_landmarks(frame, results.pose_landmarks, connections = self.customConnection, is_drawing_landmarks = False)
            for id, lm in enumerate(results.pose_landmarks.landmark):
                if id in self.showLandmarksList:
                    h, w, c = frame.shape
                    cx, cy = int(lm.x*w), int(lm.y*h)
                    if lm.visibility >= 0.9:
                        cv2.circle(frame, (cx, cy), 10, (0, 128, 0), cv2.FILLED)
                    else:
                        cv2.circle(frame, (cx, cy), 10, (0, 0, 255), cv2.FILLED)

        # Update the image
        self.frame = ImageTk.PhotoImage(image = Image.fromarray(cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)))
        self.canvas.create_image(0, 0, image = self.frame, anchor = NW)
        
        # Update the displayed text values
        if len(self.repetitionsCount) > 1:
            self.leftCounter['text'] = 'Left repetitions: ' + str(self.repetitionsCount[0])
            self.rightCounter['text'] = 'Right repetitions: ' + str(self.repetitionsCount[1])
        
        # Find the total count
        total = 0
        for count in self.repetitionsCount:
            total += count
        self.totalCounter['text'] = 'Total repetitions: ' + str(total)

        # Start timer after first repetition
        if (self.timer == 0 and total > 0):
            self.timer = time.perf_counter()

        # Continue to update
        self.window.after(5, self.update)

    def Close(self):
        stopTime = time.perf_counter()
        seconds = 0
        if (self.timer != 0):
            seconds = int(round(stopTime - self.timer))
        self.window.destroy()
        sys.stdout.write(str(self.repetitionsCount) + ' ' + str(seconds))
        sys.exit(0)

class workoutTracker:
    def __init__(self, videoSource = 0):
        self.capture = cv2.VideoCapture(videoSource)
        if not self.capture.isOpened():
            raise ValueError("Camera was not able to be opened")
        self.width = self.capture.get(cv2.CAP_PROP_FRAME_WIDTH)
        self.height = self.capture.get(cv2.CAP_PROP_FRAME_HEIGHT)
    
    def getFrame(self):
        if self.capture.isOpened():
            success, frame = self.capture.read()
            if success:
                frameRGB = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                return frame, frameRGB
            
    def trackCurls(self, poseLandmarks, repetitionsCount, previousAngle):
        if (len(previousAngle) < 2):
            previousAngle.append(180)

        if (len(repetitionsCount) < 2):
            repetitionsCount.append(0)

        # Calculate left arm angle
        leftShoulder = poseLandmarks.landmark[11]
        leftElbow = poseLandmarks.landmark[13]
        leftWrist = poseLandmarks.landmark[15]
        leftAngle = self.CalculateAngle(leftShoulder, leftElbow, leftWrist)

        # Add count if angle is right
        if (leftShoulder.visibility >= .90 and leftElbow.visibility >= .90 and leftWrist.visibility >= .90):
            if (leftAngle < 40 and previousAngle[0] > 40):
                repetitionsCount[0] = repetitionsCount[0] + 1
            previousAngle[0] = leftAngle

        # Calculate right arm angle
        rightShoulder = poseLandmarks.landmark[12]
        rightElbow = poseLandmarks.landmark[14]
        rightWrist = poseLandmarks.landmark[16]
        rightAngle = self.CalculateAngle(rightShoulder, rightElbow, rightWrist)

        # Add count if angle is right
        if (rightShoulder.visibility >= .90 and rightElbow.visibility >= .90 and rightWrist.visibility >= .90):
            if (rightAngle < 40 and previousAngle[1] > 40):
                repetitionsCount[1] = repetitionsCount[1] + 1
            previousAngle[1] = rightAngle

    def trackSquats(self, poseLandmarks, repetitionsCount, previousAngle):
        if (len(previousAngle) < 2):
            previousAngle.append(180)

        # Calculate left arm angle
        leftHip = poseLandmarks.landmark[23]
        leftKnee = poseLandmarks.landmark[25]
        leftAnkle = poseLandmarks.landmark[27]
        leftAngle = self.CalculateAngle(leftHip, leftKnee, leftAnkle)

        # Calculate right arm angle
        rightHip = poseLandmarks.landmark[24]
        rightKnee = poseLandmarks.landmark[26]
        rightAnkle = poseLandmarks.landmark[28]
        rightAngle = self.CalculateAngle(rightHip, rightKnee, rightAnkle)

        # Add count if both knees are the proper angle
        repetitionsAngle = 160
        print(leftAngle, rightAngle)
        if ((leftHip.visibility >= .90 and leftKnee.visibility >= .90 and leftAnkle.visibility >= .90) or (rightHip.visibility >= .90 and rightKnee.visibility >= .90 and rightAnkle.visibility >= .90)):
            if (leftAngle < repetitionsAngle and rightAngle < repetitionsAngle and (previousAngle[0] > repetitionsAngle or previousAngle[1] > repetitionsAngle)):
                repetitionsCount[0] = repetitionsCount[0] + 1
            previousAngle[0] = leftAngle
            previousAngle[1] = rightAngle

    def CalculateAngle(self, startPoint, anglePoint, endPoint):
        a = math.sqrt(math.pow(startPoint.x - anglePoint.x, 2) + math.pow(startPoint.y - anglePoint.y, 2))
        b = math.sqrt(math.pow(startPoint.x - endPoint.x, 2) + math.pow(startPoint.y - endPoint.y, 2))
        c = math.sqrt(math.pow(endPoint.x - anglePoint.x, 2) + math.pow(endPoint.y - anglePoint.y, 2))

        angleRadians = (math.pow(c, 2) + math.pow(a, 2) - math.pow(b, 2)) / (2 * c * a)
        angleDegrees = math.degrees(math.acos(angleRadians))
        return angleDegrees
    
    def createLandmarkConnectionList(self, showLandmarkList):
        customConnections = list(mpPose.POSE_CONNECTIONS)
        excludedLandmarks = [
            PoseLandmark.NOSE,
            PoseLandmark.LEFT_EYE_INNER,
            PoseLandmark.LEFT_EYE,
            PoseLandmark.LEFT_EYE_OUTER,
            PoseLandmark.RIGHT_EYE_INNER,
            PoseLandmark.RIGHT_EYE,
            PoseLandmark.RIGHT_EYE_OUTER,
            PoseLandmark.LEFT_EAR,
            PoseLandmark.RIGHT_EAR,
            PoseLandmark.MOUTH_LEFT,
            PoseLandmark.MOUTH_RIGHT,
            PoseLandmark.LEFT_SHOULDER,
            PoseLandmark.RIGHT_SHOULDER,
            PoseLandmark.LEFT_ELBOW,
            PoseLandmark.RIGHT_ELBOW,
            PoseLandmark.LEFT_WRIST,
            PoseLandmark.RIGHT_WRIST,
            PoseLandmark.LEFT_PINKY,
            PoseLandmark.RIGHT_PINKY,
            PoseLandmark.LEFT_INDEX,
            PoseLandmark.RIGHT_INDEX,
            PoseLandmark.LEFT_THUMB,
            PoseLandmark.RIGHT_THUMB,
            PoseLandmark.LEFT_HIP,
            PoseLandmark.RIGHT_HIP,
            PoseLandmark.LEFT_KNEE,
            PoseLandmark.RIGHT_KNEE,
            PoseLandmark.LEFT_ANKLE,
            PoseLandmark.RIGHT_ANKLE,
            PoseLandmark.LEFT_HEEL,
            PoseLandmark.RIGHT_HEEL,
            PoseLandmark.LEFT_FOOT_INDEX,
            PoseLandmark.RIGHT_FOOT_INDEX  
        ]

        # Create list landmarks to exclude when making connections
        for i in excludedLandmarks[:]:
            if i in showLandmarkList:
                excludedLandmarks.remove(i)

        # Remove the connections that are excluded
        for landmark in excludedLandmarks:
            customConnections = [connectionTuple for connectionTuple in customConnections 
                                    if landmark.value not in connectionTuple]
            
        return customConnections

    def __del__(self):
        if self.capture.isOpened():
            self.capture.release()

# Run the application
if __name__ == "__main__":
    workoutType = int(sys.argv[1])
    App(0, workoutType)
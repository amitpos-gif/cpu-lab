import cv2
import mediapipe as mp

# אתחול מודולי MediaPipe
mp_hands = mp.solutions.hands
mp_face = mp.solutions.face_mesh
mp_drawing = mp.solutions.drawing_utils

# פתיחת מצלמה
cap = cv2.VideoCapture(0)

# אתחול מודולי זיהוי (ידיים ופנים)
with mp_hands.Hands(
        static_image_mode=False,
        max_num_hands=2,
        min_detection_confidence=0.7,
        min_tracking_confidence=0.7
) as hands, mp_face.FaceMesh(
        static_image_mode=False,
        max_num_faces=2,
        refine_landmarks=True,
        min_detection_confidence=0.7,
        min_tracking_confidence=0.7
) as face_mesh:

    while cap.isOpened():
        success, frame = cap.read()
        if not success:
            print("לא הצליח לקרוא את המצלמה.")
            break

        # הפיכת צבעים ל־RGB
        image = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        image.flags.writeable = False

        # זיהוי ידיים ופנים
        hand_results = hands.process(image)
        face_results = face_mesh.process(image)

        # הפיכת צבעים חזרה ל־BGR להצגה
        image.flags.writeable = True
        image = cv2.cvtColor(image, cv2.COLOR_RGB2BGR)

        # ציור נקודות על הידיים
        if hand_results.multi_hand_landmarks:
            for hand_landmarks in hand_results.multi_hand_landmarks:
                mp_drawing.draw_landmarks(
                    image,
                    hand_landmarks,
                    mp_hands.HAND_CONNECTIONS,
                    mp_drawing.DrawingSpec(color=(0, 255, 255), thickness=2, circle_radius=3),
                    mp_drawing.DrawingSpec(color=(255, 0, 0), thickness=2)
                )

        # ציור נקודות על הפנים
        if face_results.multi_face_landmarks:
            for face_landmarks in face_results.multi_face_landmarks:
                mp_drawing.draw_landmarks(
                    image,
                    face_landmarks,
                    mp_face.FACEMESH_TESSELATION,
                    mp_drawing.DrawingSpec(color=(0, 255, 0), thickness=1, circle_radius=1),
                    mp_drawing.DrawingSpec(color=(0, 0, 255), thickness=1)
                )

        # הצגת התמונה
        cv2.imshow('Real-Time Hand & Face Detection', image)

        # יציאה בלחיצה על Q
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

# ניקוי משאבים
cap.release()
cv2.destroyAllWindows()
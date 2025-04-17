package com.brickify.frontend.utils;

import javafx.geometry.Point3D;
import javafx.scene.Group;
import javafx.scene.PerspectiveCamera;
import javafx.scene.SceneAntialiasing;
import javafx.scene.SubScene;
import javafx.scene.transform.Rotate;
import javafx.scene.transform.Transform;
import javafx.scene.transform.Translate;

public class Scene3DUtils {
    private static final double CAMERA_NEAR_CLIP = 0.1;
    private static final double CAMERA_FAR_CLIP = 10000.0;
    private static final double CAMERA_INITIAL_DISTANCE = -1000;
    private static final double CAMERA_INITIAL_X_ANGLE = 45.0;
    private static final double CAMERA_INITIAL_Y_ANGLE = 45.0;
    private static final double CAMERA_INITIAL_Z_ANGLE = 0.0;

    private static final Point3D X_AXIS = new Point3D(1, 0, 0);
    private static final Point3D Y_AXIS = new Point3D(0, 1, 0);
    private static final Point3D Z_AXIS = new Point3D(0, 0, 1);

    public static SubScene createSubScene() {
        Group root = new Group();
        SubScene subScene = new SubScene(root, 800, 600, true, SceneAntialiasing.BALANCED);
        
        // Configuration de la caméra
        PerspectiveCamera camera = new PerspectiveCamera(true);
        camera.setNearClip(CAMERA_NEAR_CLIP);
        camera.setFarClip(CAMERA_FAR_CLIP);
        camera.setTranslateZ(CAMERA_INITIAL_DISTANCE);
        
        // Ajout des transformations de base
        Rotate rotateX = new Rotate(CAMERA_INITIAL_X_ANGLE, X_AXIS);
        Rotate rotateY = new Rotate(CAMERA_INITIAL_Y_ANGLE, Y_AXIS);
        Rotate rotateZ = new Rotate(CAMERA_INITIAL_Z_ANGLE, Z_AXIS);
        
        camera.getTransforms().addAll(rotateX, rotateY, rotateZ);
        subScene.setCamera(camera);
        
        return subScene;
    }

    public static void resetCamera(SubScene subScene) {
        PerspectiveCamera camera = (PerspectiveCamera) subScene.getCamera();
        camera.setTranslateZ(CAMERA_INITIAL_DISTANCE);
        
        // Réinitialisation des rotations
        for (Transform transform : camera.getTransforms()) {
            if (transform instanceof Rotate) {
                Rotate rotate = (Rotate) transform;
                Point3D axis = rotate.getAxis();
                if (axis.equals(X_AXIS)) {
                    rotate.setAngle(CAMERA_INITIAL_X_ANGLE);
                } else if (axis.equals(Y_AXIS)) {
                    rotate.setAngle(CAMERA_INITIAL_Y_ANGLE);
                } else if (axis.equals(Z_AXIS)) {
                    rotate.setAngle(CAMERA_INITIAL_Z_ANGLE);
                }
            }
        }
    }

    public static void zoomCamera(SubScene subScene, double factor) {
        PerspectiveCamera camera = (PerspectiveCamera) subScene.getCamera();
        double currentZ = camera.getTranslateZ();
        camera.setTranslateZ(currentZ * factor);
    }

    public static void rotateCamera(SubScene subScene, double x, double y, double z) {
        PerspectiveCamera camera = (PerspectiveCamera) subScene.getCamera();
        for (Transform transform : camera.getTransforms()) {
            if (transform instanceof Rotate) {
                Rotate rotate = (Rotate) transform;
                Point3D axis = rotate.getAxis();
                if (axis.equals(X_AXIS)) {
                    rotate.setAngle(rotate.getAngle() + x);
                } else if (axis.equals(Y_AXIS)) {
                    rotate.setAngle(rotate.getAngle() + y);
                } else if (axis.equals(Z_AXIS)) {
                    rotate.setAngle(rotate.getAngle() + z);
                }
            }
        }
    }
} 
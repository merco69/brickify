package com.brickify.frontend.utils;

import javafx.scene.PerspectiveCamera;
import javafx.scene.SubScene;
import javafx.scene.transform.Rotate;
import javafx.scene.transform.Transform;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.testfx.framework.junit5.ApplicationTest;

import static org.junit.jupiter.api.Assertions.*;

class Scene3DUtilsTest extends ApplicationTest {
    private SubScene subScene;

    @BeforeEach
    void setUp() {
        subScene = Scene3DUtils.createSubScene();
    }

    @Test
    void testCreateSubScene() {
        assertNotNull(subScene);
        assertTrue(subScene.getCamera() instanceof PerspectiveCamera);
        
        PerspectiveCamera camera = (PerspectiveCamera) subScene.getCamera();
        assertEquals(-1000, camera.getTranslateZ());
        
        // Vérification des rotations initiales
        int rotateCount = 0;
        for (Transform transform : camera.getTransforms()) {
            if (transform instanceof Rotate) {
                rotateCount++;
                Rotate rotate = (Rotate) transform;
                if (rotate.getAxis().equals(new javafx.geometry.Point3D(1, 0, 0))) {
                    assertEquals(45.0, rotate.getAngle());
                } else if (rotate.getAxis().equals(new javafx.geometry.Point3D(0, 1, 0))) {
                    assertEquals(45.0, rotate.getAngle());
                } else if (rotate.getAxis().equals(new javafx.geometry.Point3D(0, 0, 1))) {
                    assertEquals(0.0, rotate.getAngle());
                }
            }
        }
        assertEquals(3, rotateCount);
    }

    @Test
    void testZoomCamera() {
        PerspectiveCamera camera = (PerspectiveCamera) subScene.getCamera();
        double initialZ = camera.getTranslateZ();
        
        Scene3DUtils.zoomCamera(subScene, 0.5);
        assertEquals(initialZ * 0.5, camera.getTranslateZ());
        
        Scene3DUtils.zoomCamera(subScene, 2.0);
        assertEquals(initialZ, camera.getTranslateZ());
    }

    @Test
    void testResetCamera() {
        // Modification des angles
        Scene3DUtils.rotateCamera(subScene, 30, 30, 30);
        
        // Réinitialisation
        Scene3DUtils.resetCamera(subScene);
        
        PerspectiveCamera camera = (PerspectiveCamera) subScene.getCamera();
        assertEquals(-1000, camera.getTranslateZ());
        
        for (Transform transform : camera.getTransforms()) {
            if (transform instanceof Rotate) {
                Rotate rotate = (Rotate) transform;
                if (rotate.getAxis().equals(new javafx.geometry.Point3D(1, 0, 0))) {
                    assertEquals(45.0, rotate.getAngle());
                } else if (rotate.getAxis().equals(new javafx.geometry.Point3D(0, 1, 0))) {
                    assertEquals(45.0, rotate.getAngle());
                } else if (rotate.getAxis().equals(new javafx.geometry.Point3D(0, 0, 1))) {
                    assertEquals(0.0, rotate.getAngle());
                }
            }
        }
    }

    @Test
    void testRotateCamera() {
        Scene3DUtils.rotateCamera(subScene, 10, 20, 30);
        
        PerspectiveCamera camera = (PerspectiveCamera) subScene.getCamera();
        for (Transform transform : camera.getTransforms()) {
            if (transform instanceof Rotate) {
                Rotate rotate = (Rotate) transform;
                if (rotate.getAxis().equals(new javafx.geometry.Point3D(1, 0, 0))) {
                    assertEquals(55.0, rotate.getAngle()); // 45 + 10
                } else if (rotate.getAxis().equals(new javafx.geometry.Point3D(0, 1, 0))) {
                    assertEquals(65.0, rotate.getAngle()); // 45 + 20
                } else if (rotate.getAxis().equals(new javafx.geometry.Point3D(0, 0, 1))) {
                    assertEquals(30.0, rotate.getAngle()); // 0 + 30
                }
            }
        }
    }
} 
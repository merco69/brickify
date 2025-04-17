package com.brickify.frontend.controllers;

import com.brickify.frontend.models.LegoPart;
import com.brickify.frontend.services.LegoService;
import com.brickify.frontend.utils.Scene3DUtils;
import javafx.fxml.FXML;
import javafx.scene.control.*;
import javafx.scene.input.*;
import javafx.scene.layout.StackPane;
import javafx.scene.SubScene;
import javafx.stage.FileChooser;
import javafx.collections.FXCollections;
import javafx.collections.ObservableList;
import javafx.scene.transform.Rotate;
import java.io.File;
import java.util.List;

public class MainController {
    @FXML private ListView<String> partsList;
    @FXML private StackPane editorPane;
    @FXML private TableView<String> propertiesTable;
    @FXML private Label statusLabel;

    private SubScene scene3D;
    private double anchorX, anchorY;
    private double anchorAngleX, anchorAngleY;
    private LegoService legoService;
    private ObservableList<String> partsObservableList;

    @FXML
    public void initialize() {
        legoService = new LegoService();
        partsObservableList = FXCollections.observableArrayList();
        partsList.setItems(partsObservableList);
        
        setupPartsList();
        setupPropertiesTable();
        setup3DScene();
        updateStatus("Application initialisée");
    }

    private void setupPartsList() {
        // Chargement des pièces depuis le backend
        List<LegoPart> parts = legoService.getAllParts();
        if (parts.isEmpty()) {
            // Si aucune pièce n'est trouvée, ajouter des pièces par défaut
            partsObservableList.addAll("Brique 2x4", "Brique 2x2", "Plaque 1x4");
            updateStatus("Aucune pièce trouvée dans le backend, utilisation des pièces par défaut");
        } else {
            // Ajouter les pièces du backend à la liste
            for (LegoPart part : parts) {
                partsObservableList.add(part.getName());
            }
            updateStatus(parts.size() + " pièces chargées depuis le backend");
        }
        
        // Ajouter un écouteur pour la sélection de pièces
        partsList.getSelectionModel().selectedItemProperty().addListener((observable, oldValue, newValue) -> {
            if (newValue != null) {
                updateStatus("Pièce sélectionnée : " + newValue);
                // TODO: Afficher les propriétés de la pièce sélectionnée
            }
        });
    }

    private void setupPropertiesTable() {
        // TODO: Configurer les colonnes de la table des propriétés
    }

    private void setup3DScene() {
        scene3D = Scene3DUtils.createSubScene();
        editorPane.getChildren().add(scene3D);

        // Gestion du zoom avec la molette de la souris
        scene3D.setOnScroll(event -> {
            double factor = event.getDeltaY() > 0 ? 1.1 : 0.9;
            Scene3DUtils.zoomCamera(scene3D, factor);
        });

        // Gestion de la rotation avec le clic droit
        scene3D.setOnMousePressed(event -> {
            if (event.isSecondaryButtonDown()) {
                anchorX = event.getSceneX();
                anchorY = event.getSceneY();
                anchorAngleX = ((Rotate) scene3D.getCamera().getTransforms().get(0)).getAngle();
                anchorAngleY = ((Rotate) scene3D.getCamera().getTransforms().get(1)).getAngle();
            }
        });

        scene3D.setOnMouseDragged(event -> {
            if (event.isSecondaryButtonDown()) {
                double dx = event.getSceneX() - anchorX;
                double dy = event.getSceneY() - anchorY;
                Scene3DUtils.rotateCamera(scene3D, dy * 0.5, dx * 0.5, 0);
            }
        });
    }

    @FXML
    private void handleNewProject() {
        // TODO: Implémenter la création d'un nouveau projet
        updateStatus("Nouveau projet créé");
    }

    @FXML
    private void handleOpenProject() {
        FileChooser fileChooser = new FileChooser();
        fileChooser.setTitle("Ouvrir un projet");
        fileChooser.getExtensionFilters().add(
            new FileChooser.ExtensionFilter("Fichiers Brickify", "*.brickify")
        );
        
        File file = fileChooser.showOpenDialog(null);
        if (file != null) {
            // TODO: Implémenter l'ouverture du projet
            updateStatus("Projet ouvert : " + file.getName());
        }
    }

    @FXML
    private void handleSaveProject() {
        FileChooser fileChooser = new FileChooser();
        fileChooser.setTitle("Enregistrer le projet");
        fileChooser.getExtensionFilters().add(
            new FileChooser.ExtensionFilter("Fichiers Brickify", "*.brickify")
        );
        
        File file = fileChooser.showSaveDialog(null);
        if (file != null) {
            // TODO: Implémenter la sauvegarde du projet
            updateStatus("Projet sauvegardé : " + file.getName());
        }
    }

    @FXML
    private void handleExport() {
        FileChooser fileChooser = new FileChooser();
        fileChooser.setTitle("Exporter le modèle");
        fileChooser.getExtensionFilters().addAll(
            new FileChooser.ExtensionFilter("Fichiers STL", "*.stl"),
            new FileChooser.ExtensionFilter("Fichiers OBJ", "*.obj")
        );
        
        File file = fileChooser.showSaveDialog(null);
        if (file != null) {
            // TODO: Implémenter l'exportation
            updateStatus("Modèle exporté : " + file.getName());
        }
    }

    @FXML
    private void handleExit() {
        // TODO: Ajouter une confirmation avant de quitter
        System.exit(0);
    }

    @FXML
    private void handleUndo() {
        // TODO: Implémenter l'annulation
        updateStatus("Action annulée");
    }

    @FXML
    private void handleRedo() {
        // TODO: Implémenter le rétablissement
        updateStatus("Action rétablie");
    }

    @FXML
    private void handleRender() {
        // TODO: Implémenter le rendu
        updateStatus("Rendu en cours...");
    }

    private void updateStatus(String message) {
        statusLabel.setText(message);
    }
} 
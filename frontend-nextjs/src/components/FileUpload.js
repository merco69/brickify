import React, { useState } from 'react';
import { Box, Button, Typography, CircularProgress } from '@mui/material';
import CloudUploadIcon from '@mui/icons-material/CloudUpload';

function FileUpload({ onFileSelect }) {
  const [isDragging, setIsDragging] = useState(false);
  const [isLoading, setIsLoading] = useState(false);

  const handleDragOver = (e) => {
    e.preventDefault();
    setIsDragging(true);
  };

  const handleDragLeave = (e) => {
    e.preventDefault();
    setIsDragging(false);
  };

  const handleDrop = (e) => {
    e.preventDefault();
    setIsDragging(false);
    const files = e.dataTransfer.files;
    if (files.length > 0) {
      handleFiles(files);
    }
  };

  const handleFileInput = (e) => {
    const files = e.target.files;
    if (files.length > 0) {
      handleFiles(files);
    }
  };

  const handleFiles = async (files) => {
    setIsLoading(true);
    try {
      // Vérification du type de fichier
      const file = files[0];
      if (!file.type.startsWith('image/')) {
        throw new Error('Veuillez télécharger une image');
      }

      // Vérification de la taille (max 5MB)
      if (file.size > 5 * 1024 * 1024) {
        throw new Error('L\'image ne doit pas dépasser 5MB');
      }

      await onFileSelect(file);
    } catch (error) {
      alert(error.message);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <Box
      sx={{
        border: '2px dashed',
        borderColor: isDragging ? 'primary.main' : 'grey.300',
        borderRadius: 2,
        p: 3,
        textAlign: 'center',
        backgroundColor: isDragging ? 'action.hover' : 'background.paper',
        cursor: 'pointer',
        transition: 'all 0.2s ease',
      }}
      onDragOver={handleDragOver}
      onDragLeave={handleDragLeave}
      onDrop={handleDrop}
    >
      <input
        type="file"
        accept="image/*"
        onChange={handleFileInput}
        style={{ display: 'none' }}
        id="file-upload"
      />
      <label htmlFor="file-upload">
        <Button
          component="span"
          variant="contained"
          startIcon={isLoading ? <CircularProgress size={20} /> : <CloudUploadIcon />}
          disabled={isLoading}
        >
          {isLoading ? 'Téléchargement...' : 'Sélectionner une image'}
        </Button>
      </label>
      <Typography variant="body2" color="text.secondary" sx={{ mt: 2 }}>
        ou glissez-déposez une image ici
      </Typography>
      <Typography variant="caption" color="text.secondary" display="block" sx={{ mt: 1 }}>
        Formats acceptés: JPG, PNG. Taille maximale: 5MB
      </Typography>
    </Box>
  );
}

export default FileUpload; 
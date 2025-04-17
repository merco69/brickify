import React, { useState } from 'react';
import { Container, Typography, Box, Paper, CircularProgress } from '@mui/material';
import FileUpload from '../components/FileUpload';

function Analyze() {
  const [analyzing, setAnalyzing] = useState(false);
  const [result, setResult] = useState(null);
  const [error, setError] = useState(null);

  const handleFileSelect = async (file) => {
    setAnalyzing(true);
    setError(null);
    setResult(null);

    try {
      const formData = new FormData();
      formData.append('image', file);

      const response = await fetch('http://localhost:8000/api/analyze', {
        method: 'POST',
        body: formData,
      });

      if (!response.ok) {
        throw new Error('Erreur lors de l\'analyse de l\'image');
      }

      const data = await response.json();
      setResult(data);
    } catch (err) {
      setError(err.message);
    } finally {
      setAnalyzing(false);
    }
  };

  return (
    <Container maxWidth="md">
      <Box sx={{ mt: 4, mb: 4 }}>
        <Typography variant="h4" component="h1" gutterBottom align="center">
          Analyse de briques LEGO
        </Typography>
        <Typography variant="body1" color="text.secondary" align="center" paragraph>
          Téléchargez une photo de vos briques LEGO pour obtenir une analyse détaillée
        </Typography>
      </Box>

      <Paper elevation={3} sx={{ p: 4, mb: 4 }}>
        <FileUpload onFileSelect={handleFileSelect} />
      </Paper>

      {analyzing && (
        <Box sx={{ display: 'flex', justifyContent: 'center', my: 4 }}>
          <CircularProgress />
        </Box>
      )}

      {error && (
        <Paper elevation={3} sx={{ p: 3, mb: 4, bgcolor: 'error.light' }}>
          <Typography color="error">{error}</Typography>
        </Paper>
      )}

      {result && (
        <Paper elevation={3} sx={{ p: 4 }}>
          <Typography variant="h6" gutterBottom>
            Résultats de l'analyse
          </Typography>
          <pre style={{ whiteSpace: 'pre-wrap' }}>
            {JSON.stringify(result, null, 2)}
          </pre>
        </Paper>
      )}
    </Container>
  );
}

export default Analyze; 
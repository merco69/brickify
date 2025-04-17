import React from 'react';
import { AppBar, Toolbar, Typography, Button, Box } from '@mui/material';
import { Link as RouterLink } from 'react-router-dom';

function Navbar() {
  return (
    <AppBar position="static">
      <Toolbar>
        <Typography variant="h6" component="div" sx={{ flexGrow: 1 }}>
          Brickify
        </Typography>
        <Box>
          <Button color="inherit" component={RouterLink} to="/">
            Accueil
          </Button>
          <Button color="inherit" component={RouterLink} to="/analyze">
            Analyser
          </Button>
          <Button color="inherit" component={RouterLink} to="/login">
            Connexion
          </Button>
        </Box>
      </Toolbar>
    </AppBar>
  );
}

export default Navbar; 
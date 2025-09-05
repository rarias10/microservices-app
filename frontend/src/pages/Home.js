import React from 'react';
import { useSelector } from 'react-redux';

const Home = () => {
  const { isAuthenticated, user } = useSelector(state => state.auth);

  return (
    <div className="home-container">
      <div className="welcome-message">
        {isAuthenticated ? (
          <>
            <h1 className="welcome-title">Welcome back, {user?.name}!</h1>
            <p className="welcome-subtitle">You are successfully logged in to your dashboard.</p>
          </>
        ) : (
          <>
            <h1 className="welcome-title">Welcome to MicroApp</h1>
            <p className="welcome-subtitle">Please login or register to continue.</p>
          </>
        )}
      </div>
    </div>
  );
};

export default Home;
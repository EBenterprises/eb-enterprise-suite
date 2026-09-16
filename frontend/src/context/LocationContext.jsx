import React, { createContext, useContext, useState } from 'react';

const LocationContext = createContext();

export function LocationProvider({ children }) {
  const [tempLocation, setTempLocation] = useState({ lat: null, lng: null, description: '' });
  const [isSharing, setIsSharing] = useState(false);

  const requestLiveGPS = () => {
    if (!navigator.geolocation) {
      alert('Geolocation is not supported by your browser');
      return;
    }
    setIsSharing(true);
    navigator.geolocation.getCurrentPosition(
      (position) => {
        setTempLocation({
          lat: position.coords.latitude,
          lng: position.coords.longitude,
          description: 'Active Live GPS Coordinate'
        });
        setIsSharing(false);
      },
      () => {
        alert('Unable to capture location.');
        setIsSharing(false);
      }
    );
  };

  return (
    <LocationContext.Provider value={{ tempLocation, setTempLocation, isSharing, requestLiveGPS }}>
      {children}
    </LocationContext.Provider>
  );
}

export const useLocation = () => useContext(LocationContext);

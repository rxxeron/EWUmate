import React, { createContext, useState, useContext, useEffect } from 'react';
import { useColorScheme } from 'react-native';

const LightTheme = {
  dark: false,
  colors: {
    primary: '#4F46E5',
    background: '#F3F4F6',
    card: '#FFFFFF',
    text: '#1F2937',
    subtext: '#6B7280',
    border: '#E5E7EB',
    notification: '#DC2626',
    accent: '#F3F4F6',
    white: '#FFFFFF',
    textInverse: '#FFFFFF',
  },
};

const DarkTheme = {
  dark: true,
  colors: {
    primary: '#6366F1',
    background: '#111827',
    card: '#1F2937',
    text: '#F9FAFB',
    subtext: '#9CA3AF',
    border: '#374151',
    notification: '#EF4444',
    accent: '#374151',
    white: '#1F2937',
    textInverse: '#1F2937',
  },
};

const ThemeContext = createContext({
  theme: LightTheme,
  toggleTheme: () => {},
});

export const ThemeProvider = ({ children }: { children: React.ReactNode }) => {
  const systemScheme = useColorScheme();
  const [isDarkMode, setIsDarkMode] = useState(systemScheme === 'dark');

  const theme = isDarkMode ? DarkTheme : LightTheme;

  const toggleTheme = () => {
    setIsDarkMode((prev) => !prev);
  };

  useEffect(() => {
    setIsDarkMode(systemScheme === 'dark');
  }, [systemScheme]);

  return (
    <ThemeContext.Provider value={{ theme, toggleTheme }}>
      {children}
    </ThemeContext.Provider>
  );
};

export const useTheme = () => useContext(ThemeContext);

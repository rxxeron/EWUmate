import { Stack } from 'expo-router';
import { CourseProvider } from '../context/CourseContext';
import { ThemeProvider } from '../context/ThemeContext';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { useEffect } from 'react';
import { registerForPushNotificationsAsync } from '../utils/notifications';

export default function RootLayout() {
  useEffect(() => {
    registerForPushNotificationsAsync();
  }, []);

  return (
    <SafeAreaProvider>
      <ThemeProvider>
        <CourseProvider>
          <Stack screenOptions={{ headerShown: false }}>
            <Stack.Screen name="(tabs)" />
          </Stack>
        </CourseProvider>
      </ThemeProvider>
    </SafeAreaProvider>
  );
}

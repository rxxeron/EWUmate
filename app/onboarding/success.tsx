import React, { useEffect, useRef } from 'react';
import { View, Text, StyleSheet, Animated } from 'react-native';
import { useRouter } from 'expo-router';

export default function RegistrationSuccess() {
  const router = useRouter();
  const scale = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    // Animate tick
    Animated.spring(scale, {
      toValue: 1,
      friction: 5,
      tension: 40,
      useNativeDriver: true,
    }).start();

    // Redirect after 2.5 seconds
    const timer = setTimeout(() => {
      router.replace('/onboarding/program-selection'); // Use replace to prevent going back
    }, 2500);

    return () => clearTimeout(timer);
  }, []);

  return (
    <View style={styles.container}>
      <Animated.View style={[styles.circle, { transform: [{ scale }] }]}>
        <Text style={styles.tick}>✓</Text>
      </Animated.View>
      <Text style={styles.text}>Registration Successful</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
    justifyContent: 'center',
    alignItems: 'center',
  },
  circle: {
    width: 120,
    height: 120,
    borderRadius: 60,
    backgroundColor: '#34C759', // Green
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 24,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.2,
    shadowRadius: 5,
    elevation: 8,
  },
  tick: {
    fontSize: 60,
    color: '#fff',
    fontWeight: 'bold',
  },
  text: {
    fontSize: 24,
    fontWeight: '600',
    color: '#333',
  },
});

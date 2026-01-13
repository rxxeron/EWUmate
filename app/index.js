import { useEffect, useState } from 'react';
import { View, ActivityIndicator } from 'react-native';
import { Redirect } from 'expo-router';
import { onAuthStateChanged } from 'firebase/auth';
import { doc, getDoc } from 'firebase/firestore';
import { auth, db } from '../firebaseConfig';

export default function Index() {
  const [loading, setLoading] = useState(true);
  const [user, setUser] = useState(null);
  const [onboardingCompleted, setOnboardingCompleted] = useState(false);

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, async (currentUser) => {
      if (currentUser) {
        setUser(currentUser);
        try {
          const userDoc = await getDoc(doc(db, 'users', currentUser.uid));
          // Check if onboardingCompleted is explicitly true
          if (userDoc.exists() && userDoc.data()?.onboardingCompleted === true) {
            setOnboardingCompleted(true);
          } else {
            setOnboardingCompleted(false);
          }
        } catch (error) {
          console.error("Error fetching user data:", error);
          setOnboardingCompleted(false);
        }
      } else {
        setUser(null);
      }
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  if (loading) {
    return (
      <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center' }}>
        <ActivityIndicator size="large" color="#007AFF" />
      </View>
    );
  }

  if (!user) {
    return <Redirect href="/auth/login" />;
  }

  if (onboardingCompleted) {
    return <Redirect href="/(tabs)/dashboard" />;
  }

  return <Redirect href="/onboarding/program-selection" />;
}

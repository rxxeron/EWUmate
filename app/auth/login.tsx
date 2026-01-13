import React, { useState } from 'react';
import { View, Text, TextInput, TouchableOpacity, StyleSheet, Image, Alert, ActivityIndicator } from 'react-native';
import { useRouter } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';
import { signInWithEmailAndPassword } from 'firebase/auth';
import { doc, getDoc, collection, query, where, getDocs } from 'firebase/firestore';
import { auth, db } from '../../firebaseConfig';

export default function Login() {
  const router = useRouter();
  const [identifier, setIdentifier] = useState(''); // Email or Username
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);

  const handleLogin = async () => {
    if (!identifier || !password) {
        Alert.alert("Error", "Please enter username/email and password");
        return;
    }

    try {
        setLoading(true);
        let emailToUse = identifier;
        
        // Check if input looks like an email using simple regex
        const isEmail = identifier.includes('@');
        
        if (!isEmail) {
            // It's a username! We need to find the email associated with it.
            const usersRef = collection(db, "users");
            const q = query(usersRef, where("username", "==", identifier));
            const querySnapshot = await getDocs(q);

            if (querySnapshot.empty) {
                throw new Error("Username not found");
            }
            
            // Get the first match (Usernames should ideally be unique)
            const userDoc = querySnapshot.docs[0].data();
            emailToUse = userDoc.email;
        } else {
             emailToUse = identifier;
        }

        const userCredential = await signInWithEmailAndPassword(auth, emailToUse, password);
        const uid = userCredential.user.uid;

        // Check Onboarding Status
        const userDoc = await getDoc(doc(db, "users", uid));
        if (userDoc.exists()) {
            const userData = userDoc.data();
            if (userData.onboardingCompleted) {
                router.replace('/(tabs)/dashboard');
            } else {
                // Resume onboarding
                router.replace('/onboarding/program-selection');
            }
        } else {
             // Fallback
             router.replace('/(tabs)/dashboard');
        }

    } catch (error: any) {
        Alert.alert("Login Failed", error.message);
    } finally {
        setLoading(false);
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.content}>
        <Text style={styles.title}>Student Portal</Text>
        <Text style={styles.subtitle}>Sign in to continue</Text>
        <TextInput 
          placeholder="Username or Email" 
          style={styles.input} 
          value={identifier}
          onChangeText={setIdentifier}
          placeholderTextColor="#666"
          autoCapitalize="none"
        />
        
        <TextInput 
          placeholder="Password" 
          style={styles.input}
          secureTextEntry
          value={password}
          onChangeText={setPassword}
          placeholderTextColor="#666"
        />

        <TouchableOpacity style={styles.button} onPress={handleLogin} disabled={loading}>
          {loading ? <ActivityIndicator color="#fff"/> : <Text style={styles.buttonText}>Login</Text>}
        </TouchableOpacity>

        <View style={styles.footer}>
          <Text style={styles.footerText}>Don't have an account?</Text>
          <TouchableOpacity onPress={() => router.push('/auth/register')}>
            <Text style={styles.link}> Register</Text>
          </TouchableOpacity>
        </View>
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
  },
  content: {
    flex: 1,
    padding: 24,
    justifyContent: 'center',
  },
  title: {
    fontSize: 32,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 8,
    textAlign: 'center',
  },
  subtitle: {
    fontSize: 16,
    color: '#666',
    marginBottom: 48,
    textAlign: 'center',
  },
  input: {
    backgroundColor: '#f5f5f5',
    padding: 16,
    borderRadius: 12,
    marginBottom: 16,
    fontSize: 16,
  },
  button: {
    backgroundColor: '#007AFF',
    padding: 16,
    borderRadius: 12,
    marginTop: 16,
    alignItems: 'center',
  },
  buttonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
  footer: {
    flexDirection: 'row',
    justifyContent: 'center',
    marginTop: 32,
  },
  footerText: {
    color: '#666',
    fontSize: 14,
  },
  link: {
    color: '#007AFF',
    fontSize: 14,
    fontWeight: '600',
  },
});

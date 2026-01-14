import React, { useState } from 'react';
import { View, Text, TextInput, TouchableOpacity, StyleSheet, Image, ScrollView, Alert, ActivityIndicator, KeyboardAvoidingView, Platform } from 'react-native';
import { useRouter } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';
import { createUserWithEmailAndPassword } from 'firebase/auth';
import { doc, setDoc } from 'firebase/firestore';
import { ref, uploadBytes, getDownloadURL } from 'firebase/storage';
import * as ImagePicker from 'expo-image-picker';
import { auth, db, storage } from '../../firebaseConfig';

export default function Register() {
  const router = useRouter();
  const [fullName, setFullName] = useState(''); 
  const [username, setUsername] = useState(''); // Added Username field
  const [email, setEmail] = useState(''); 
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [image, setImage] = useState<string | null>(null);

  const pickImage = async () => {
    const result = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ImagePicker.MediaTypeOptions.Images,
      allowsEditing: true,
      aspect: [1, 1],
      quality: 0.5,
    });

    if (!result.canceled) {
      setImage(result.assets[0].uri);
    }
  };

  const uploadImageAsync = async (uri: string, uid: string) => {
    try {
      const response = await fetch(uri);
      const blob = await response.blob();
      const storageRef = ref(storage, `profile_pictures/${uid}`);
      await uploadBytes(storageRef, blob);
      // blob.close(); // Not required in all environments, but safe
      return await getDownloadURL(storageRef);
    } catch (e) {
      console.error(e);
      throw e;
    }
  };
  
  const handleRegister = async () => {
    if (!email || !password || !fullName || !username) {
        Alert.alert("Error", "Please fill in all fields");
        return;
    }

    try {
        setLoading(true);
        // 1. Create Auth User
        const userCredential = await createUserWithEmailAndPassword(auth, email, password);
        const user = userCredential.user;

        let photoURL = null;
        if (image) {
           try {
             photoURL = await uploadImageAsync(image, user.uid);
           } catch (e) {
             console.log("Image upload failed", e);
           }
        }

        // 2. Create User Document in Firestore
        await setDoc(doc(db, "users", user.uid), {
            uid: user.uid,
            fullName: fullName, 
            username: username, // Saved Username
            email: email,
            photoURL: photoURL,
            createdAt: new Date().toISOString(),
            onboardingCompleted: false
        });

        // 3. Navigate
        router.push('/onboarding/success');
    } catch (error: any) {
        Alert.alert("Registration Failed", error.message);
    } finally {
        setLoading(false);
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      <KeyboardAvoidingView 
        behavior={Platform.OS === "ios" ? "padding" : "height"} 
        style={{ flex: 1 }}
      >
        <ScrollView contentContainerStyle={styles.content} showsVerticalScrollIndicator={false}>
          <Text style={styles.title}>Create Account</Text>
          <Text style={styles.subtitle}>Sign up to get started</Text>
          
          {/* Profile Pic Placeholder */}
        <TouchableOpacity style={styles.imageUpload} onPress={pickImage}>
           {image ? (
             <Image source={{ uri: image }} style={styles.uploadedImage} />
           ) : (
             <View style={styles.circle}>
               <Text style={styles.cameraIcon}>📷</Text>
             </View>
           )}
           <Text style={styles.uploadText}>{image ? 'Change Picture' : 'Upload Profile Picture'}</Text>
           <Text style={styles.optionalText}>(Optional)</Text>
        </TouchableOpacity>

        <TextInput 
          placeholder="Full Name (e.g. Md. Rakibul Hasan)" 
          style={styles.input} 
          value={fullName}
          onChangeText={setFullName}
          placeholderTextColor="#666"
        />
        <TextInput 
          placeholder="Username" 
          style={styles.input} 
          value={username}
          onChangeText={setUsername}
          placeholderTextColor="#666"
          autoCapitalize="none"
        />
        <TextInput 
          placeholder="Email" 
          style={styles.input} 
          value={email}
          onChangeText={setEmail}
          placeholderTextColor="#666"
          autoCapitalize="none"
          keyboardType="email-address"
        />
        <TextInput 
          placeholder="Password" 
          style={styles.input} 
          secureTextEntry 
          value={password}
          onChangeText={setPassword}
          placeholderTextColor="#666"
        />

        <TouchableOpacity style={styles.button} onPress={handleRegister} disabled={loading}>
          {loading ? <ActivityIndicator color="#fff"/> : <Text style={styles.buttonText}>Register</Text>}
        </TouchableOpacity>

        <TouchableOpacity onPress={() => router.back()} style={styles.footerLink}>
          <Text style={styles.link}>Already have an account? Login</Text>
        </TouchableOpacity>
      </ScrollView>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
  },
  content: {
    padding: 24,
    justifyContent: 'center',
    minHeight: '100%',
  },
  title: {
    fontSize: 28,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 8,
    textAlign: 'center',
  },
  subtitle: {
    fontSize: 16,
    color: '#666',
    marginBottom: 32,
    textAlign: 'center',
  },
  imageUpload: {
    alignItems: 'center',
    marginBottom: 32,
  },
  uploadedImage: {
    width: 100,
    height: 100,
    borderRadius: 50,
    marginBottom: 8,
  },
  circle: {
    width: 100,
    height: 100,
    borderRadius: 50,
    backgroundColor: '#f0f0f0',
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 8,
    borderWidth: 1,
    borderColor: '#ddd',
  },
  cameraIcon: {
    fontSize: 32,
  },
  uploadText: {
    color: '#007AFF',
    fontSize: 16,
    fontWeight: '500',
  },
  optionalText: {
    color: '#999',
    fontSize: 12,
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
  footerLink: {
    marginTop: 24,
    alignItems: 'center',
  },
  link: {
    color: '#007AFF',
    fontSize: 14,
    fontWeight: '600',
  },
});

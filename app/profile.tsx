import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, Image, TextInput, ScrollView, Alert, ActivityIndicator } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { router, Stack } from 'expo-router';
import { auth, db, storage } from '../firebaseConfig'; // Ensure storage is exported in firebaseConfig
import { signOut, updateProfile } from 'firebase/auth';
import { doc, getDoc, updateDoc } from 'firebase/firestore';
import * as ImagePicker from 'expo-image-picker';
// Note: Actual image upload to Firebase Storage would require a blob/fetch, which is complex in Expo.
// For this demo, we might store the local URI or base64 if small, or simulate upload.
// Given time constraints, I will implement the picker but maybe warn about persistence if storage rules or blob util is missing.
// I will try to use the photoURL auth property.

export default function ProfileScreen() {
    const [loading, setLoading] = useState(false);
    const [userData, setUserData] = useState({
        fullName: '',
        studentId: '',
        phone: '',
        email: ''
    });
    const [photo, setPhoto] = useState<string | null>(null);

    useEffect(() => {
        loadProfile();
    }, []);

    const loadProfile = async () => {
        const user = auth.currentUser;
        if (user) {
            setPhoto(user.photoURL);
            setUserData(prev => ({ ...prev, email: user.email || '' }));
            
            // Allow Firestore data to override/supplement
            const userDoc = await getDoc(doc(db, 'users', user.uid));
            if (userDoc.exists()) {
                const data = userDoc.data();
                setUserData(prev => ({
                    ...prev,
                    fullName: data.fullName || user.displayName || '',
                    studentId: data.studentId || '',
                    phone: data.phone || ''
                }));
            }
        }
    };

    const handleSignOut = async () => {
        try {
            await signOut(auth);
            router.replace('/auth/login');
        } catch (error) {
            Alert.alert("Error", "Failed to sign out");
        }
    };

    const pickImage = async () => {
        const result = await ImagePicker.launchImageLibraryAsync({
            mediaTypes: ['images'], // Updated: mediaTypes should be an array or ImagePicker.MediaTypeOptions.Images
            allowsEditing: true,
            aspect: [1, 1],
            quality: 0.5,
        });

        if (!result.canceled) {
            setPhoto(result.assets[0].uri);
            // In a real app, upload result.assets[0].uri to Firebase Storage here
            // then getDownloadURL and set that.
            // For now, we just show it locally to demonstrate the feature.
            Alert.alert("Note", "Image selection works, but cloud upload requires Firebase Storage setup.");
        }
    };

    const handleSave = async () => {
        setLoading(true);
        try {
            const user = auth.currentUser;
            if (!user) return;

            // Update Auth Profile
            await updateProfile(user, {
                displayName: userData.fullName,
                photoURL: photo
            });

            // Update Firestore
            await updateDoc(doc(db, 'users', user.uid), {
                fullName: userData.fullName,
                studentId: userData.studentId,
                phone: userData.phone,
                // photoURL: photo // Save here if you upload to storage
            });
            
            Alert.alert("Success", "Profile updated successfully!");
        } catch (e: any) {
            Alert.alert("Error", e.message || "Unknown error occurred");
        } finally {
            setLoading(false);
        }
    };

    return (
        <SafeAreaView style={styles.container}>
            <Stack.Screen options={{ headerShown: false }} />
            
            <View style={styles.header}>
                <TouchableOpacity onPress={() => router.back()} style={styles.backBtn}>
                    <Ionicons name="arrow-back" size={24} color="#333" />
                </TouchableOpacity>
                <Text style={styles.title}>My Profile</Text>
                <View style={{width: 40}} /> 
            </View>

            <ScrollView contentContainerStyle={styles.content}>
                {/* Photo Section */}
                <View style={styles.photoContainer}>
                    {photo ? (
                        <Image source={{ uri: photo }} style={styles.avatar} />
                    ) : (
                        <View style={[styles.avatar, styles.avatarPlaceholder]}>
                            <Ionicons name="person" size={60} color="#9CA3AF" />
                        </View>
                    )}
                    <TouchableOpacity style={styles.editPhotoBadge} onPress={pickImage}>
                        <Ionicons name="camera" size={20} color="#fff" />
                    </TouchableOpacity>
                </View>

                {/* Form */}
                <View style={styles.form}>
                    <View style={styles.inputGroup}>
                        <Text style={styles.label}>Full Name</Text>
                        <TextInput 
                            style={styles.input} 
                            value={userData.fullName}
                            onChangeText={t => setUserData({...userData, fullName: t})}
                        />
                    </View>

                    <View style={styles.inputGroup}>
                        <Text style={styles.label}>Student ID</Text>
                        <TextInput 
                            style={styles.input} 
                            value={userData.studentId}
                            onChangeText={t => setUserData({...userData, studentId: t})}
                            keyboardType="numeric"
                        />
                    </View>

                    <View style={styles.inputGroup}>
                        <Text style={styles.label}>Email (Read Only)</Text>
                        <TextInput 
                            style={[styles.input, styles.disabledInput]} 
                            value={userData.email}
                            editable={false}
                        />
                    </View>

                    <View style={styles.inputGroup}>
                        <Text style={styles.label}>Phone</Text>
                        <TextInput 
                            style={styles.input} 
                            value={userData.phone}
                            onChangeText={t => setUserData({...userData, phone: t})}
                            keyboardType="phone-pad"
                        />
                    </View>

                    <TouchableOpacity style={styles.saveBtn} onPress={handleSave} disabled={loading}>
                        {loading ? <ActivityIndicator color="#fff" /> : <Text style={styles.saveBtnText}>Save Changes</Text>}
                    </TouchableOpacity>

                    <TouchableOpacity style={styles.logoutBtn} onPress={handleSignOut}>
                        <Ionicons name="log-out-outline" size={20} color="#DC2626" />
                        <Text style={styles.logoutText}>Sign Out</Text>
                    </TouchableOpacity>
                </View>
            </ScrollView>
        </SafeAreaView>
    );
}

const styles = StyleSheet.create({
    container: { flex: 1, backgroundColor: '#fff' },
    header: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', paddingHorizontal: 20, paddingVertical: 10, borderBottomWidth: 1, borderBottomColor: '#F3F4F6' },
    backBtn: { width: 40, height: 40, borderRadius: 20, backgroundColor: '#F3F4F6', justifyContent: 'center', alignItems: 'center' },
    title: { fontSize: 18, fontWeight: 'bold' },
    
    content: { padding: 20 },
    
    photoContainer: { alignItems: 'center', marginBottom: 30, position: 'relative' },
    avatar: { width: 120, height: 120, borderRadius: 60, backgroundColor: '#E5E7EB', borderWidth: 4, borderColor: '#fff', shadowColor: '#000', shadowOpacity: 0.1, shadowRadius: 10, elevation: 5 },
    avatarPlaceholder: { justifyContent: 'center', alignItems: 'center', backgroundColor: '#F3F4F6' },
    editPhotoBadge: { position: 'absolute', bottom: 0, right: '35%', backgroundColor: '#4F46E5', width: 36, height: 36, borderRadius: 18, justifyContent: 'center', alignItems: 'center', borderWidth: 3, borderColor: '#fff' },
    
    form: {},
    inputGroup: { marginBottom: 20 },
    label: { fontSize: 13, fontWeight: '600', color: '#6B7280', marginBottom: 8 },
    input: { backgroundColor: '#F9FAFB', borderWidth: 1, borderColor: '#E5E7EB', borderRadius: 12, padding: 14, fontSize: 16, color: '#1F2937' },
    disabledInput: { color: '#9CA3AF', backgroundColor: '#F3F4F6' },

    saveBtn: { backgroundColor: '#4F46E5', borderRadius: 12, padding: 16, alignItems: 'center', marginTop: 10 },
    saveBtnText: { color: '#fff', fontWeight: 'bold', fontSize: 16 },

    logoutBtn: { flexDirection: 'row', alignItems: 'center', justifyContent: 'center', marginTop: 30, padding: 16 },
    logoutText: { color: '#DC2626', fontWeight: '600', fontSize: 16, marginLeft: 8 }
});

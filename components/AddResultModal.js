import React, { useState } from 'react';
import { View, Text, StyleSheet, Modal, TouchableOpacity, TextInput, ScrollView, Alert } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { db, auth } from '../firebaseConfig';
import { doc, updateDoc, arrayUnion } from 'firebase/firestore';

const GRADES = ['A+', 'A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'D', 'F', 'W', 'I'];
const SEMESTERS = ['Spring', 'Summer', 'Fall'];

export default function AddResultModal({ visible, onClose, onSave }) {
    const [semesterTerm, setSemesterTerm] = useState('Fall');
    const [semesterYear, setSemesterYear] = useState(new Date().getFullYear().toString());
    const [courseCode, setCourseCode] = useState('');
    const [courseTitle, setCourseTitle] = useState('');
    const [credits, setCredits] = useState('3');
    const [grade, setGrade] = useState('A');
    const [loading, setLoading] = useState(false);

    const handleSave = async () => {
        // Validation: Prevent adding results for current/future semesters
        const now = new Date();
        const currentYear = now.getFullYear();
        const currentMonth = now.getMonth(); // 0-11
        
        // Semester Values: Spring=0, Summer=1, Fall=2
        // Default Logic: 
        // Jan-May (Spring active) -> Current=0
        // Jun-Sep (Summer active) -> Current=1
        // Oct-Dec (Fall active)   -> Current=2
        let currentSemVal = 0;
        if (currentMonth > 4) currentSemVal = 1;
        if (currentMonth > 8) currentSemVal = 2;

        const semMap = { 'Spring': 0, 'Summer': 1, 'Fall': 2 };
        const inputSemVal = semMap[semesterTerm];
        const inputYear = parseInt(semesterYear);

        // Restriction Check
        if (inputYear > currentYear) {
            Alert.alert("Restriction", "You cannot add results for future years.");
            return;
        }
        if (inputYear === currentYear && inputSemVal >= currentSemVal) {
             Alert.alert("Restriction", "You cannot add results for the current or future semesters. Please wait for the term to finish.");
             return;
        }

        if (!courseCode || !courseTitle || !credits) {
            Alert.alert("Error", "Please fill all fields");
            return;
        }

        setLoading(true);
        try {
            const user = auth.currentUser;
            if (!user) throw new Error("No user");

            const semesterId = `${semesterTerm}${semesterYear}`;

            const newResult = {
                id: Date.now().toString(),
                semesterId,
                courseCode: courseCode.toUpperCase(),
                courseTitle,
                credits: parseFloat(credits),
                grade,
                timestamp: new Date().toISOString()
            };

            const userRef = doc(db, 'users', user.uid);
            await updateDoc(userRef, {
                academicResults: arrayUnion(newResult)
            });

            if (onSave) onSave(newResult);
            // Reset form
            setCourseCode('');
            setCourseTitle('');
            onClose();
            Alert.alert("Success", "Grade added successfully");
        } catch (e) {
            console.error("Grade Save Error:", e);
            Alert.alert("Error", "Could not save grade.");
        } finally {
            setLoading(false);
        }
    };

    return (
        <Modal visible={visible} animationType="slide" transparent={true} onRequestClose={onClose}>
            <View style={styles.overlay}>
                <View style={styles.modalContent}>
                    <View style={styles.header}>
                        <Text style={styles.title}>Add Course Result</Text>
                        <TouchableOpacity onPress={onClose}>
                            <Ionicons name="close" size={24} color="#333" />
                        </TouchableOpacity>
                    </View>

                    <ScrollView style={styles.form}>
                        {/* Semester */}
                        <Text style={styles.label}>Semester</Text>
                        <View style={styles.row}>
                            <ScrollView horizontal showsHorizontalScrollIndicator={false} style={{flex: 1}}>
                                {SEMESTERS.map(sem => (
                                    <TouchableOpacity 
                                        key={sem} 
                                        style={[styles.chip, semesterTerm === sem && styles.activeChip]}
                                        onPress={() => setSemesterTerm(sem)}
                                    >
                                        <Text style={[styles.chipText, semesterTerm === sem && styles.activeChipText]}>{sem}</Text>
                                    </TouchableOpacity>
                                ))}
                            </ScrollView>
                            <TextInput 
                                style={[styles.input, {width: 80}]} 
                                value={semesterYear}
                                onChangeText={setSemesterYear}
                                keyboardType="numeric"
                                placeholder="Year"
                            />
                        </View>

                        {/* Course Info */}
                        <Text style={styles.label}>Course Code</Text>
                        <TextInput 
                            style={styles.input}
                            value={courseCode}
                            onChangeText={setCourseCode}
                            placeholder="e.g. CSE101"
                        />

                        <Text style={styles.label}>Course Title</Text>
                        <TextInput 
                            style={styles.input}
                            value={courseTitle}
                            onChangeText={setCourseTitle}
                            placeholder="e.g. Computer Fundamentals"
                        />

                        {/* Grade & Credits */}
                        <View style={styles.row}>
                            <View style={{flex: 1}}>
                                <Text style={styles.label}>Credits</Text>
                                <TextInput 
                                    style={styles.input}
                                    value={credits}
                                    onChangeText={setCredits}
                                    keyboardType="numeric"
                                    placeholder="3.0"
                                />
                            </View>
                            <View style={{flex: 2, marginLeft: 12}}>
                                <Text style={styles.label}>Grade</Text>
                                <ScrollView horizontal showsHorizontalScrollIndicator={false}>
                                    {GRADES.map(g => (
                                        <TouchableOpacity 
                                            key={g} 
                                            style={[styles.gradeChip, grade === g && styles.activeGradeChip]}
                                            onPress={() => setGrade(g)}
                                        >
                                            <Text style={[styles.gradeText, grade === g && styles.activeGradeText]}>{g}</Text>
                                        </TouchableOpacity>
                                    ))}
                                </ScrollView>
                            </View>
                        </View>
                    </ScrollView>

                    <View style={styles.footer}>
                        <TouchableOpacity style={styles.saveBtn} onPress={handleSave} disabled={loading}>
                            <Text style={styles.saveBtnText}>{loading ? "Saving..." : "Add Result"}</Text>
                        </TouchableOpacity>
                    </View>
                </View>
            </View>
        </Modal>
    );
}

const styles = StyleSheet.create({
    overlay: { flex: 1, backgroundColor: 'rgba(0,0,0,0.5)', justifyContent: 'flex-end' },
    modalContent: { backgroundColor: '#fff', borderTopLeftRadius: 20, borderTopRightRadius: 20, padding: 20, maxHeight: '90%' },
    header: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 },
    title: { fontSize: 20, fontWeight: 'bold' },
    form: { maxHeight: 500 },
    label: { fontSize: 14, fontWeight: '600', color: '#374151', marginBottom: 8, marginTop: 12 },
    input: { backgroundColor: '#F3F4F6', borderRadius: 8, padding: 12, fontSize: 16 },
    
    row: { flexDirection: 'row', alignItems: 'center' },
    chip: { paddingHorizontal: 16, paddingVertical: 8, borderRadius: 20, backgroundColor: '#F3F4F6', marginRight: 8 },
    activeChip: { backgroundColor: '#EEF2FF', borderWidth: 1, borderColor: '#4F46E5' },
    chipText: { color: '#4B5563', fontWeight: '500' },
    activeChipText: { color: '#4F46E5', fontWeight: '700' },

    gradeChip: { width: 40, height: 40, borderRadius: 20, backgroundColor: '#F3F4F6', marginRight: 8, justifyContent: 'center', alignItems: 'center' },
    activeGradeChip: { backgroundColor: '#4F46E5' },
    gradeText: { fontWeight: '600', color: '#374151' },
    activeGradeText: { color: '#fff' },

    footer: { marginTop: 20 },
    saveBtn: { backgroundColor: '#4F46E5', padding: 16, borderRadius: 12, alignItems: 'center' },
    saveBtnText: { color: '#fff', fontSize: 16, fontWeight: 'bold' }
});

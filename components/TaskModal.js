import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, Modal, TouchableOpacity, TextInput, ScrollView, Alert, Platform } from 'react-native';
import { format, parse, isValid, addMinutes, differenceInMinutes, parseISO } from 'date-fns';
import { Ionicons } from '@expo/vector-icons';
import { db, auth } from '../firebaseConfig';
import { doc, updateDoc, arrayUnion } from 'firebase/firestore';
import { scheduleTaskNotification } from '../utils/notifications';
import DateTimePicker from '@react-native-community/datetimepicker';

const TASK_TYPES = ['Quiz', 'Exam', 'Presentation', 'Assignment', 'Viva'];

export default function TaskModal({ visible, onClose, courses = [], onSave }) {
    const [selectedCourse, setSelectedCourse] = useState(null);
    const [taskType, setTaskType] = useState('Assignment');
    const [dueDate, setDueDate] = useState(new Date());
    const [showDatePicker, setShowDatePicker] = useState(false);
    const [showTimePicker, setShowTimePicker] = useState(false);
    const [description, setDescription] = useState('');
    const [loading, setLoading] = useState(false);

    // Reset when opening
    useEffect(() => {
        if (visible) {
            setSelectedCourse(courses.length > 0 ? courses[0] : null);
            setDueDate(new Date());
            setTaskType('Assignment');
            setDescription('');
        }
    }, [visible]);

    const onChangeDate = (event, selectedDate) => {
        setShowDatePicker(false);
        if (selectedDate) {
            const current = new Date(selectedDate);
            // Keep the time from the previous state, only update date
            const newDate = new Date(dueDate);
            newDate.setFullYear(current.getFullYear(), current.getMonth(), current.getDate());
            setDueDate(newDate);
        }
    };

    const onChangeTime = (event, selectedDate) => {
        setShowTimePicker(false);
        if (selectedDate) {
            const current = new Date(selectedDate);
            // Keep the date from the previous state, only update time
            const newDate = new Date(dueDate);
            newDate.setHours(current.getHours(), current.getMinutes());
            setDueDate(newDate);
        }
    };

    const handleSave = async () => {
        if (!selectedCourse) {
            Alert.alert("Error", "Please select a course.");
            return;
        }

        setLoading(true);
        try {
            const user = auth.currentUser;
            if (!user) throw new Error("No user");

            const newTask = {
                id: Date.now().toString(), // Simple ID
                courseId: selectedCourse.id || selectedCourse.docId,
                courseName: selectedCourse.courseName,
                courseCode: selectedCourse.code || selectedCourse.docId || "UNKNOWN",
                type: taskType,
                dueDate: dueDate.toISOString(), // ISO string from Date object
                description,
                createdAt: new Date().toISOString(),
                status: 'pending' 
            };

            const userRef = doc(db, 'users', user.uid);
            await updateDoc(userRef, {
                tasks: arrayUnion(newTask)
            });

            // Schedule notification
            await scheduleTaskNotification(newTask);

            if (onSave) onSave(newTask);
            onClose();
            Alert.alert("Success", "Task created successfully!");
        } catch (e) {
            console.error("Task Save Error:", e);
            Alert.alert("Error", "Could not save task.");
        } finally {
            setLoading(false);
        }
    };

    return (
        <Modal visible={visible} animationType="slide" transparent={true} onRequestClose={onClose}>
            <View style={styles.overlay}>
                <View style={styles.modalContent}>
                    <View style={styles.header}>
                        <Text style={styles.title}>New Academic Task</Text>
                        <TouchableOpacity onPress={onClose}>
                            <Ionicons name="close" size={24} color="#333" />
                        </TouchableOpacity>
                    </View>

                    <ScrollView style={styles.form}>
                        {/* Course Selector */}
                        <Text style={styles.label}>Select Course</Text>
                        <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.chipScroll}>
                            {courses.map(course => {
                                // Extract code
                                const code = course.code || (course.docId ? course.docId.split('_')[1] : "UNK");
                                const isSelected = selectedCourse && (selectedCourse.docId === course.docId);
                                return (
                                    <TouchableOpacity 
                                        key={course.docId} 
                                        style={[styles.chip, isSelected && styles.activeChip]}
                                        onPress={() => setSelectedCourse(course)}
                                    >
                                        <Text style={[styles.chipText, isSelected && styles.activeChipText]}>{code}</Text>
                                    </TouchableOpacity>
                                );
                            })}
                        </ScrollView>
                        <Text style={{fontSize: 12, color:'gray', marginBottom: 12}}>
                            {selectedCourse ? selectedCourse.courseName : "No course selected"}
                        </Text>

                        {/* Type Selector */}
                        <Text style={styles.label}>Task Type</Text>
                        <ScrollView horizontal showsHorizontalScrollIndicator={false} style={{marginBottom: 12}}>
                            {TASK_TYPES.map(type => (
                                <TouchableOpacity 
                                    key={type} 
                                    style={[styles.typeChip, taskType === type && styles.activeTypeChip]}
                                    onPress={() => setTaskType(type)}
                                >
                                    <Text style={[styles.typeText, taskType === type && styles.activeTypeText]}>{type}</Text>
                                </TouchableOpacity>
                            ))}
                        </ScrollView>

                        {/* Date & Time */}
                        <View style={styles.row}>
                            <View style={styles.half}>
                                <Text style={styles.label}>Date</Text>
                                <TouchableOpacity onPress={() => setShowDatePicker(true)} style={styles.inputButton}>
                                    <Text>{format(dueDate, 'PPP')}</Text>
                                </TouchableOpacity>
                            </View>
                            <View style={styles.half}>
                                <Text style={styles.label}>Time</Text>
                                <TouchableOpacity onPress={() => setShowTimePicker(true)} style={styles.inputButton}>
                                    <Text>{format(dueDate, 'p')}</Text>
                                </TouchableOpacity>
                            </View>
                        </View>
                        
                        {showDatePicker && (
                            <DateTimePicker
                                testID="dateTimePicker"
                                value={dueDate}
                                mode="date"
                                is24Hour={true}
                                display={Platform.OS === 'ios' ? 'spinner' : 'default'}
                                onChange={onChangeDate}
                            />
                        )}
                        
                        {showTimePicker && (
                            <DateTimePicker
                                testID="timePicker"
                                value={dueDate}
                                mode="time"
                                is24Hour={false} // Use AM/PM as per user region usually
                                display={Platform.OS === 'ios' ? 'spinner' : 'default'}
                                onChange={onChangeTime}
                            />
                        )}

                        {/* Description (Optional) */}
                        <Text style={styles.label}>Note (Optional)</Text>
                        <TextInput 
                            style={[styles.input, styles.textArea]} 
                            value={description} 
                            onChangeText={setDescription}
                            multiline
                            numberOfLines={3}
                            placeholder="Chapter 5, topics..."
                        />
                    </ScrollView>

                    <View style={styles.footer}>
                        <TouchableOpacity style={styles.saveBtn} onPress={handleSave} disabled={loading}>
                            <Text style={styles.saveBtnText}>{loading ? "Saving..." : "Create Task"}</Text>
                        </TouchableOpacity>
                    </View>
                </View>
            </View>
        </Modal>
    );
}

const styles = StyleSheet.create({
    overlay: { flex: 1, backgroundColor: 'rgba(0,0,0,0.5)', justifyContent: 'flex-end' },
    modalContent: { backgroundColor: '#fff', borderTopLeftRadius: 20, borderTopRightRadius: 20, padding: 20, maxHeight: '80%' },
    header: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 },
    title: { fontSize: 20, fontWeight: 'bold' },
    form: { maxHeight: 400 },
    label: { fontSize: 14, fontWeight: '600', color: '#374151', marginBottom: 8, marginTop: 12 },
    input: { backgroundColor: '#F3F4F6', borderRadius: 8, padding: 12, fontSize: 16 },
    textArea: { height: 80, textAlignVertical: 'top' },
    
    chipScroll: { flexDirection: 'row', marginBottom: 8 },
    chip: { paddingHorizontal: 16, paddingVertical: 8, borderRadius: 20, backgroundColor: '#F3F4F6', marginRight: 8, borderWidth: 1, borderColor: '#E5E7EB' },
    activeChip: { backgroundColor: '#EEF2FF', borderColor: '#4F46E5' },
    chipText: { color: '#4B5563', fontWeight: '500' },
    activeChipText: { color: '#4F46E5', fontWeight: '700' },

    typeChip: { paddingHorizontal: 16, paddingVertical: 8, borderRadius: 8, backgroundColor: '#F3F4F6', marginRight: 8 },
    activeTypeChip: { backgroundColor: '#4F46E5' },
    typeText: { color: '#4B5563' },
    activeTypeText: { color: '#fff', fontWeight: '600' },

    row: { flexDirection: 'row', gap: 12 },
    half: { flex: 1 },
    inputButton: { backgroundColor: '#F3F4F6', borderRadius: 8, padding: 12, justifyContent: 'center' },

    footer: { marginTop: 20 },
    saveBtn: { backgroundColor: '#4F46E5', padding: 16, borderRadius: 12, alignItems: 'center' },
    saveBtnText: { color: '#fff', fontSize: 16, fontWeight: 'bold' }
});

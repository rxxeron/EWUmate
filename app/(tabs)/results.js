import React, { useState, useEffect, useCallback } from 'react';
import { View, Text, StyleSheet, ScrollView, RefreshControl, TouchableOpacity, StatusBar } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { db, auth } from '../../firebaseConfig';
import { doc, getDoc } from 'firebase/firestore';
import { calculateCGPA } from '../../utils/grade-helper';
import { Ionicons } from '@expo/vector-icons';
import AddResultModal from '../../components/AddResultModal';
import { LinearGradient } from 'expo-linear-gradient';

const TOTAL_CREDITS_REQUIRED = 140; // Default bachelor requirement

export default function DegreeProgressScreen() {
    const [academicResults, setAcademicResults] = useState([]);
    const [stats, setStats] = useState({ cgpa: "0.00", totalCredits: 0 });
    const [loading, setLoading] = useState(true);
    const [refreshing, setRefreshing] = useState(false);
    const [showAddModal, setShowAddModal] = useState(false);

    useEffect(() => {
        fetchResults();
    }, []);

    const onRefresh = useCallback(() => {
        setRefreshing(true);
        fetchResults();
    }, []);

    const fetchResults = async () => {
        try {
            const user = auth.currentUser;
            if (!user) return;
            const userRef = doc(db, 'users', user.uid);
            // We could use onSnapshot for real-time updates but getDoc is fine for this tab
            const userSnap = await getDoc(userRef);

            if (userSnap.exists()) {
                const data = userSnap.data();
                const rawResults = data.academicResults || [];
                
                const calculated = calculateCGPA(rawResults);
                setAcademicResults(calculated.processedResults);
                setStats({ cgpa: calculated.cgpa, totalCredits: calculated.totalCredits });
            }
        } catch (error) {
            console.log("Error fetching results", error);
        } finally {
            setLoading(false);
            setRefreshing(false);
        }
    };

    const groupResultsBySemester = () => {
        const groups = {};
        academicResults.forEach(res => {
            const sem = res.semesterId || "Unknown";
            if (!groups[sem]) groups[sem] = [];
            groups[sem].push(res);
        });
        
        return Object.keys(groups).sort((a,b) => {
             const getVal = (s) => {
                 const year = parseInt(s.slice(-4)) || 0;
                 const term = s.slice(0, -4);
                 let tVal = 0;
                 if (term === 'Fall') tVal = 3;
                 if (term === 'Summer') tVal = 2;
                 if (term === 'Spring') tVal = 1;
                 return year * 10 + tVal;
             };
             return getVal(b) - getVal(a);
        }).map(sem => ({
            semester: sem,
            courses: groups[sem]
        }));
    };

    const renderSemesterBlock = (group) => {
        let totalP = 0; 
        let totalC = 0;
        group.courses.forEach(c => {
            // Logic: Include in term GPA if it's a graded course, even if retaken later? 
            // Usually Term GPA reflects what happened THAT term.
            // But our calculateCGPA might have marked it 'calculated: false' if retaken.
            // For Term GPA, we should likely look at the raw grade of that attempt.
            const rawGrade = c.originalGrade || c.displayGrade || c.grade;
            // Need to check if it's a GPA grade
            if (['A+','A','A-','B+','B','B-','C+','C','D','F'].includes(rawGrade)) {
                 const pt = (require('../../utils/grade-helper').getGradePoint(rawGrade));
                 const cr = parseFloat(c.credits) || 0;
                 totalP += (pt * cr);
                 totalC += cr;
            }
        });
        const termGPA = totalC > 0 ? (totalP / totalC).toFixed(2) : "0.00";

        return (
            <View key={group.semester} style={styles.semesterBlock}>
                <View style={styles.semHeader}>
                    <Text style={styles.semTitle}>{group.semester.replace(/([A-Z][a-z]+)(\d{4})/, '$1 $2')}</Text>
                    <View style={styles.termBadge}>
                        <Text style={styles.termText}>Term GPA: {termGPA}</Text>
                    </View>
                </View>

                {/* Table Header */}
                <View style={styles.tableHead}>
                    <Text style={[styles.th, {flex: 2}]}>Code</Text>
                    <Text style={[styles.th, {flex: 4}]}>Course Title</Text>
                    <Text style={[styles.th, {flex: 1, textAlign: 'center'}]}>Cr</Text>
                    <Text style={[styles.th, {flex: 1, textAlign: 'center'}]}>Gpa</Text>
                </View>

                {group.courses.map((course, idx) => (
                    <View key={idx} style={[styles.tableRow, idx % 2 === 1 && styles.tableRowAlt]}>
                        <Text style={[styles.td, {flex: 2, fontWeight: '600'}]}>{course.courseCode}</Text>
                        <Text style={[styles.td, {flex: 4}]} numberOfLines={1}>{course.courseTitle}</Text>
                        <Text style={[styles.td, {flex: 1, textAlign: 'center'}]}>{course.credits}</Text>
                        <View style={{flex: 1, alignItems: 'center'}}>
                            <View style={[
                                styles.gradeBadge, 
                                course.displayGrade === 'F' ? {backgroundColor: '#FEE2E2'} : 
                                course.displayGrade?.includes('R') ? {backgroundColor: '#FFF7ED'} : {}
                            ]}>
                                <Text style={[
                                    styles.gradeText, 
                                    course.displayGrade === 'F' ? {color: '#DC2626'} : 
                                    course.displayGrade?.includes('R') ? {color: '#EA580C'} : {}
                                ]}>{course.displayGrade}</Text>
                            </View>
                        </View>
                    </View>
                ))}
            </View>
        );
    };

    const remainingCredits = Math.max(0, TOTAL_CREDITS_REQUIRED - stats.totalCredits);
    const progressPercent = Math.min(100, (stats.totalCredits / TOTAL_CREDITS_REQUIRED) * 100);

    return (
        <SafeAreaView style={styles.container} edges={['top']}>
            <StatusBar barStyle="dark-content" />
            <View style={styles.header}>
                <Text style={styles.screenTitle}>Degree Progress</Text>
                <TouchableOpacity style={styles.addBtn} onPress={() => setShowAddModal(true)}>
                    <Ionicons name="add" size={24} color="#4F46E5" />
                </TouchableOpacity>
            </View>

            <ScrollView 
                contentContainerStyle={styles.scrollContent}
                refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} />}
            >
                {/* Stats Card */}
                <LinearGradient colors={['#4F46E5', '#4338CA']} style={styles.statsCard}>
                    <View style={styles.statsRow}>
                        <View style={styles.statItem}>
                            <Text style={styles.statLabel}>CGPA</Text>
                            <Text style={styles.statValue}>{stats.cgpa}</Text>
                        </View>
                        <View style={styles.statDivider} />
                        <View style={styles.statItem}>
                            <Text style={styles.statLabel}>Credits Earned</Text>
                            <Text style={styles.statValue}>{stats.totalCredits}</Text>
                        </View>
                        <View style={styles.statDivider} />
                        <View style={styles.statItem}>
                            <Text style={styles.statLabel}>Remaining</Text>
                            <Text style={styles.statValue}>{remainingCredits}</Text>
                        </View>
                    </View>
                    
                    {/* Progress Bar */}
                    <View style={styles.progressContainer}>
                        <View style={styles.progressBarBg}>
                            <View style={[styles.progressBarFill, {width: `${progressPercent}%`}]} />
                        </View>
                        <Text style={styles.progressText}>{progressPercent.toFixed(1)}% Completed</Text>
                    </View>
                </LinearGradient>

                {academicResults.length === 0 ? (
                    <View style={styles.emptyState}>
                        <Ionicons name="school-outline" size={64} color="#D1D5DB" />
                        <Text style={styles.emptyText}>No academic records found.</Text>
                        <Text style={styles.emptySubText}>Add your completed courses to track progress.</Text>
                        <TouchableOpacity style={styles.ctaBtn} onPress={() => setShowAddModal(true)}>
                            <Text style={styles.ctaBtnText}>Add First Result</Text>
                        </TouchableOpacity>
                    </View>
                ) : (
                    <View style={styles.resultsList}>
                        {groupResultsBySemester().map(renderSemesterBlock)}
                    </View>
                )}
            </ScrollView>

            <AddResultModal 
                visible={showAddModal} 
                onClose={() => setShowAddModal(false)}
                onSave={() => {
                    fetchResults();
                }}
            />
        </SafeAreaView>
    );
}

const styles = StyleSheet.create({
    container: { flex: 1, backgroundColor: '#F9FAFB' },
    header: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', paddingHorizontal: 20, paddingVertical: 16, backgroundColor: '#fff', borderBottomWidth: 1, borderBottomColor: '#F3F4F6' },
    screenTitle: { fontSize: 24, fontWeight: '800', color: '#111827' },
    addBtn: { width: 40, height: 40, borderRadius: 20, backgroundColor: '#EEF2FF', alignItems: 'center', justifyContent: 'center' },
    
    scrollContent: { padding: 20 },
    
    statsCard: { padding: 20, borderRadius: 20, marginBottom: 24, shadowColor: '#4F46E5', shadowOffset: {width: 0, height: 4}, shadowOpacity: 0.2, shadowRadius: 8, elevation: 4 },
    statsRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 },
    statItem: { alignItems: 'center', flex: 1 },
    statLabel: { color: '#E0E7FF', fontSize: 12, fontWeight: '600', marginBottom: 4 },
    statValue: { color: '#fff', fontSize: 24, fontWeight: 'bold' },
    statDivider: { width: 1, height: 30, backgroundColor: 'rgba(255,255,255,0.2)' },
    
    progressContainer: {},
    progressBarBg: { height: 6, backgroundColor: 'rgba(0,0,0,0.2)', borderRadius: 3, marginBottom: 8 },
    progressBarFill: { height: 6, backgroundColor: '#fff', borderRadius: 3 },
    progressText: { color: '#E0E7FF', fontSize: 12, fontWeight: '500', textAlign: 'right' },

    semesterBlock: { backgroundColor: '#fff', borderRadius: 16, padding: 16, marginBottom: 16, shadowColor: '#000', shadowOpacity: 0.05, shadowRadius: 5, elevation: 1 },
    semHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 },
    semTitle: { fontSize: 18, fontWeight: 'bold', color: '#1F2937' },
    termBadge: { backgroundColor: '#F3F4F6', paddingHorizontal: 12, paddingVertical: 4, borderRadius: 12 },
    termText: { fontSize: 12, fontWeight: '600', color: '#4B5563' },

    tableHead: { flexDirection: 'row', borderBottomWidth: 1, borderBottomColor: '#E5E7EB', paddingBottom: 8, marginBottom: 8 },
    th: { fontSize: 12, fontWeight: '700', color: '#9CA3AF' },
    
    tableRow: { flexDirection: 'row', paddingVertical: 8, alignItems: 'center' },
    tableRowAlt: { backgroundColor: '#F9FAFB' },
    td: { fontSize: 13, color: '#374151' },
    gradeBadge: { paddingHorizontal: 8, paddingVertical: 2, borderRadius: 6, backgroundColor: '#ECFDF5' },
    gradeText: { fontSize: 12, fontWeight: '700', color: '#059669' },

    emptyState: { alignItems: 'center', padding: 40 },
    emptyText: { fontSize: 18, fontWeight: '600', color: '#374151', marginTop: 16 },
    emptySubText: { textAlign: 'center', color: '#6B7280', marginTop: 8, marginBottom: 24 },
    ctaBtn: { backgroundColor: '#4F46E5', paddingHorizontal: 24, paddingVertical: 12, borderRadius: 8 },
    ctaBtnText: { color: '#fff', fontWeight: '600' }
});

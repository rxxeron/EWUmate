import React, { useState, useEffect, useContext } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, Alert, Linking, ActivityIndicator, ScrollView } from 'react-native';
import { CourseContext } from '../../context/CourseContext';
import { format, subDays, addDays, isBefore, isAfter } from 'date-fns';
import { getStorage, ref, getDownloadURL } from 'firebase/storage';
import { storage } from '../../firebaseConfig';

// Configuration for Advising
const ADVISING_CONFIG = {
  semesterStart: new Date('2025-01-11'), // Start of current semester
  advisingStart: new Date('2025-04-15'), // Next advising starts
  lockDelayDays: 5, // Days after semester start to keep open
  unlockDaysBefore: 7, // Unlock planner 7 days before advising
};

const SEMESTERS = [
  "Spring 2025",
  "Summer 2025",
  "Fall 2025"
];

// Additional resources for the current semester
const ACADEMIC_RESOURCES = [
  { 
    title: "Academic Calendar Spring 2025", 
    fileName: "Academic Calender Spring 2025.pdf", 
    folder: "academiccalender" 
  },
  { 
    title: "Exam Schedule Spring 2025", 
    fileName: "Exam Schedule Spring 2025.pdf", 
    folder: "academiccalender" 
  }
];

export default function PlannerScreen() {
  const { semesterConfig } = useContext(CourseContext);
  const [isAdvisingUnlocked, setIsAdvisingUnlocked] = useState(false);
  const [nextAdvisingDate, setNextAdvisingDate] = useState(null);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    const now = new Date();
    
    // Merge hardcoded defaults with dynamic updates from Database (via Context)
    let config = { ...ADVISING_CONFIG };
    if (semesterConfig) {
        if(semesterConfig.semesterStart) config.semesterStart = new Date(semesterConfig.semesterStart);
        if(semesterConfig.advisingStart) config.advisingStart = new Date(semesterConfig.advisingStart);
    }

    // 1. Calculations
    const lockDate = addDays(config.semesterStart, config.lockDelayDays);
    const unlockDate = subDays(config.advisingStart, config.unlockDaysBefore);
    
    setNextAdvisingDate(unlockDate);

    // 2. Logic: 
    // Open if: (Now < SemesterStart + 5 days) OR (Now >= AdvisingStart - 7 days)
    const isEarlySemester = isBefore(now, lockDate);
    const isAdvisingPeriod = isAfter(now, unlockDate) || now.getTime() === unlockDate.getTime();

    setIsAdvisingUnlocked(isEarlySemester || isAdvisingPeriod);
  }, [semesterConfig]);

  const handleOpenFile = async (folderName, fileName) => {
    const fileRef = ref(storage, `${folderName}/${fileName}`);

    setLoading(true);

    try {
      // Get the download URL from Firebase Storage
      const url = await getDownloadURL(fileRef);
      
      // Open the PDF in the system browser / viewer
      const supported = await Linking.canOpenURL(url);
      if (supported) {
        await Linking.openURL(url);
      } else {
        Alert.alert("Error", "Can't open this file format on your device.");
      }
    } catch (error) {
      console.error(error);
      Alert.alert(
        "File Not Found", 
        `Could not find "${fileName}" in ${folderName}. Please check Firebase Storage.`
      );
    } finally {
      setLoading(false);
    }
  };

  const handleDownloadPdf = (semesterName) => {
     // Wrapper to match previous signature, calling the generic handler
     // Folder: facultylist (as per user instruction)
     const fileName = `Faculty List ${semesterName}.pdf`;
     handleOpenFile('facultylist', fileName);
  };

  // Render UI
  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.title}>Planner & Resources</Text>
        <Text style={styles.subtitle}>Access academic documents and advising lists</Text>
      </View>

      <ScrollView contentContainerStyle={styles.list}>
        
        {/* Academic Resources Section (Always Visible) */}
        <Text style={styles.sectionHeader}>Important Documents</Text>
        {ACADEMIC_RESOURCES.map((resource) => (
          <TouchableOpacity 
            key={resource.fileName} 
            style={[styles.card, styles.resourceCard]}
            onPress={() => handleOpenFile(resource.folder, resource.fileName)}
            disabled={loading}
          >
            <View style={[styles.cardIconContainer, styles.resourceIconContainer]}>
              <Text style={styles.cardIcon}>📅</Text>
            </View>
            <View style={styles.cardContent}>
              <Text style={styles.semesterName}>{resource.title}</Text>
              <Text style={styles.cardAction}>Tap to view PDF</Text>
            </View>
            <View>
              <Text style={styles.arrow}>→</Text>
            </View>
          </TouchableOpacity>
        ))}

        {/* Advising Section (Conditionally Locked) */}
        <Text style={styles.sectionHeader}>Faculty Lists (Advising)</Text>
        
        {!isAdvisingUnlocked ? (
          <View style={styles.lockedContainer}>
            <Text style={styles.lockIcon}>🔒</Text>
            <Text style={styles.lockedTitle}>Advising Locked</Text>
            <Text style={styles.lockedText}>
              Planning tools for the next semester will unlock on {nextAdvisingDate ? format(nextAdvisingDate, 'MMMM do, yyyy') : '...'}
            </Text>
          </View>
        ) : (
          SEMESTERS.map((semester) => (
            <TouchableOpacity 
              key={semester} 
              style={styles.card}
              onPress={() => handleDownloadPdf(semester)}
              disabled={loading}
            >
              <View style={styles.cardIconContainer}>
                <Text style={styles.cardIcon}>📄</Text>
              </View>
              <View style={styles.cardContent}>
                <Text style={styles.semesterName}>{semester}</Text>
                <Text style={styles.cardAction}>Tap to view Faculty List</Text>
              </View>
              <View>
                <Text style={styles.arrow}>→</Text>
              </View>
            </TouchableOpacity>
          ))
        )}

      </ScrollView>

      {loading && (
        <View style={styles.loadingOverlay}>
          <ActivityIndicator size="large" color="#4A90E2" />
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F5F7FA',
    padding: 20,
  },
  // Removed old full-screen locked container styles in favor of inline locked styles
  lockedContainer: {
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 24,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 16,
    borderWidth: 1,
    borderColor: '#eee',
    borderStyle: 'dashed'
  },
  lockIcon: {
    fontSize: 60,
    marginBottom: 20,
  },
  lockedTitle: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 10,
  },
  lockedText: {
    fontSize: 16,
    color: '#666',
    textAlign: 'center',
  },
  header: {
    marginTop: 40,
    marginBottom: 30,
  },
  title: {
    fontSize: 28,
    fontWeight: 'bold',
    color: '#1A1A1A',
  },
  subtitle: {
    fontSize: 16,
    color: '#666',
    marginTop: 8,
  },
  list: {
    paddingBottom: 20,
  },
  card: {
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    padding: 16,
    marginBottom: 16,
    flexDirection: 'row',
    alignItems: 'center',
    // Shadows
    elevation: 2,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
  },
  resourceIconContainer: {
    backgroundColor: '#E8EAF6',
  },
  resourceCard: {
    // backgroundColor: '#F0F4FF', // Slight tint for resources - Defined below
    borderColor: '#E3F2FD',
    borderWidth: 1,
  },
  sectionHeader: {
    fontSize: 20,
    fontWeight: '700',
    color: '#444',
    marginBottom: 12,
    marginTop: 8,
  },
  cardIconContainer: {
    width: 48,
    height: 48,
    backgroundColor: '#E3F2FD',
    borderRadius: 24,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 16,
  },
  cardIcon: {
    fontSize: 24,
  },
  cardContent: {
    flex: 1,
  },
  semesterName: {
    fontSize: 18,
    fontWeight: '600',
    color: '#333',
  },
  cardAction: {
    fontSize: 14,
    color: '#4A90E2',
    marginTop: 4,
  },
  arrow: {
    fontSize: 20,
    color: '#CCC',
  },
  loadingOverlay: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: 'rgba(255,255,255,0.7)',
    justifyContent: 'center',
    alignItems: 'center',
  }
});

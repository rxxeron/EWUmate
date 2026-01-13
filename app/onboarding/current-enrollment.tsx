import React, { useState } from 'react';
import { View, Text, TextInput, StyleSheet, FlatList, TouchableOpacity, Alert, ActivityIndicator } from 'react-native';
import { useRouter } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';
import { auth, db } from '../../firebaseConfig';
import { doc, updateDoc, collection, getDocs } from 'firebase/firestore';

// Default to current semester for onboarding (Spring 2026)
const CURRENT_SEMESTER_COLLECTION = 'courses_Spring2026';

type Enrollment = {
  courseId: string;
  section: string;
  docId: string; // The specific section ID for linking to Dashboard
};

export default function CurrentEnrollment() {
  const router = useRouter();
  const [search, setSearch] = useState('');
  const [enrollments, setEnrollments] = useState([] as Enrollment[]);
  const [loading, setLoading] = useState(false);
  const [courses, setCourses] = useState([] as any[]);

  React.useEffect(() => {
     fetchSemesterCourses();
  }, []);

  const fetchSemesterCourses = async () => {
    try {
        setLoading(true);
        // Fetch specific sections for the current semester so Dashboard Schedule works
        const colRef = collection(db, CURRENT_SEMESTER_COLLECTION);
        const snapshot = await getDocs(colRef);
        const fetched = snapshot.docs.map(doc => ({
            ...doc.data(),
            docId: doc.id 
        }));
        setCourses(fetched);
    } catch (e) { 
        console.log('Error fetching semester courses', e);
    } finally {
        setLoading(false);
    }
  };
  
  const filteredCourses = courses.filter((c: any) => {
      const name = c.courseName || c.name || "";
      const code = c.code || (c.docId ? c.docId.split('_')[1] : ""); 
      const q = search.toLowerCase();
      return name.toLowerCase().includes(q) || code.toLowerCase().includes(q);
  });

  const handleSelectCourse = (course: any) => {
    // Check if already enrolled (by docId to handle specific sections)
    const existing = enrollments.find((e: Enrollment) => e.docId === course.docId);
    if (existing) {
       // Remove
       setEnrollments((prev: Enrollment[]) => prev.filter((e: Enrollment) => e.docId !== course.docId));
    } else {
       // Check limit
       if (enrollments.length >= 5) {
           Alert.alert("Enrollment Limit", "You can only enroll in a maximum of 5 courses per semester.");
           return;
       }

       // Add
       // For semester data, docId is usually "Spring2026_Code_Section"
       // We'll store the whole ID so CourseContext can find it.
       const newEntry = {
           courseId: course.code,
           section: course.section || "1",
           docId: course.docId
       };
       setEnrollments(prev => [...prev, newEntry]);
    }
  };

  const handleNext = async () => {
    const user = auth.currentUser;
    if (user) {
        try {
            // Save just the IDs (docIds) to enrolledSections for the Dashboard
            const sectionIds = enrollments.map(e => e.docId);
            
            await updateDoc(doc(db, "users", user.uid), {
                enrolledSections: sectionIds,
                onboardingComplete: true
            });
            router.push('/(tabs)/dashboard');
        } catch (error) {
            Alert.alert("Error", "Could not save enrollment");
        }
    } else {
        router.push('/(tabs)/dashboard');
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.title}>Current Enrollment</Text>
        <Text style={styles.subtitle}>Select courses you are taking this semester (Spring 2026)</Text>
        
        <TextInput 
          style={styles.searchBar}
          placeholder="Search courses (e.g. CSE101)"
          value={search}
          onChangeText={setSearch}
        />
      </View>

      {loading ? (
          <ActivityIndicator size="large" color="#4F46E5" style={{marginTop: 50}} />
      ) : (
        <FlatList 
            data={filteredCourses}
            keyExtractor={item => item.docId || item.code}
            contentContainerStyle={styles.list}
            renderItem={({ item }) => {
            const isSelected = enrollments.some(e => e.docId === item.docId);
            const displayCode = item.code || (item.docId ? item.docId.split('_')[1] : "UNK");
            
            return (
                <TouchableOpacity 
                style={[styles.item, isSelected && styles.selectedItem]}
                onPress={() => handleSelectCourse(item)}
                >
                <View>
                    <Text style={[styles.code, isSelected && styles.selectedText]}>{displayCode}</Text>
                    <Text style={[styles.name, isSelected && styles.selectedText]}>{item.courseName || item.name}</Text>
                    {item.startTime && (
                         <Text style={styles.details}>
                             {item.day || "TBA"} {item.startTime} | Room {item.room}
                         </Text>
                    )}
                </View>
                {isSelected && <Text style={styles.check}>✓</Text>}
                </TouchableOpacity>
            );
            }}
        />
      )}

      <View style={styles.footer}>
        <Text style={styles.counter}>{enrollments.length} courses selected</Text>
        <TouchableOpacity style={styles.button} onPress={handleNext}>
          <Text style={styles.buttonText}>Finish Setup</Text>
        </TouchableOpacity>
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
  },
  header: {
    padding: 20,
    backgroundColor: '#fff',
    borderBottomWidth: 1,
    borderBottomColor: '#f0f0f0',
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#333',
  },
  subtitle: {
    fontSize: 14,
    color: '#666',
    marginTop: 4,
    marginBottom: 16,
  },
  searchBar: {
    backgroundColor: '#f5f5f5',
    padding: 12,
    borderRadius: 8,
    fontSize: 16,
  },
  list: {
    padding: 20,
    paddingBottom: 100, // Space for footer
  },
  item: {
    padding: 16,
    borderRadius: 12,
    backgroundColor: '#f9f9f9',
    marginBottom: 12,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    borderWidth: 1,
    borderColor: '#f0f0f0',
  },
  selectedItem: {
    backgroundColor: '#EEF2FF',
    borderColor: '#4F46E5',
  },
  code: {
    fontSize: 14,
    fontWeight: 'bold',
    color: '#666',
    marginBottom: 4,
  },
  name: {
    fontSize: 16,
    fontWeight: '600',
    color: '#333',
  },
  selectedText: {
    color: '#4F46E5',
  },
  details: {
      fontSize: 12,
      color: '#888',
      marginTop: 4
  },
  check: {
    fontSize: 20,
    color: '#4F46E5',
    fontWeight: 'bold',
  },
  footer: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    backgroundColor: '#fff',
    padding: 20,
    borderTopWidth: 1,
    borderTopColor: '#f0f0f0',
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  counter: {
    fontSize: 16,
    fontWeight: '600',
    color: '#4F46E5',
  },
  button: {
    backgroundColor: '#4F46E5',
    paddingVertical: 12,
    paddingHorizontal: 24,
    borderRadius: 8,
  },
  buttonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
});

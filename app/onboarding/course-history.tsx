import React, { useState } from 'react';
import { View, Text, TextInput, StyleSheet, FlatList, TouchableOpacity, Alert } from 'react-native';
import { useRouter } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';
import { auth, db } from '../../firebaseConfig';
import { doc, updateDoc, getDoc } from 'firebase/firestore';
import { COURSE_CATALOG } from '../../utils/course-catalog';

export default function CourseHistory() {
  const router = useRouter();
  const [search, setSearch] = useState('');
  const [completedCourses, setCompletedCourses] = useState([] as string[]);
  const [courses, setCourses] = useState(COURSE_CATALOG);

  React.useEffect(() => {
     fetchCatalog();
  }, []);

  const fetchCatalog = async () => {
    try {
        const docRef = doc(db, 'metadata', 'courses');
        const snap = await getDoc(docRef);
        if (snap.exists() && snap.data().catalog) {
            setCourses(snap.data().catalog);
        }
    } catch (e) { console.log('Using local catalog'); }
  };

  const filteredCourses = courses.filter((c: any) => 
    c.name.toLowerCase().includes(search.toLowerCase()) || 
    c.code.toLowerCase().includes(search.toLowerCase())
  );

  const toggleCourse = (code: string) => {
    setCompletedCourses((prev: string[]) => 
      prev.includes(code) ? prev.filter((c: string) => c !== code) : [...prev, code]
    );
  };


  const handleNext = async () => {
    const user = auth.currentUser;
    if (user) {
        try {
            await updateDoc(doc(db, "users", user.uid), {
                completedCourses: completedCourses
            });
            router.push('/onboarding/current-enrollment');
        } catch (error) {
            Alert.alert("Error", "Could not save courses");
        }
    } else {
        router.push('/onboarding/current-enrollment');
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.title}>Course History</Text>
        <Text style={styles.subtitle}>Select courses you have completed</Text>
        
        <TextInput 
          style={styles.searchBar}
          placeholder="Search courses (e.g. CSE101)"
          value={search}
          onChangeText={setSearch}
        />
      </View>

      <FlatList 
        data={filteredCourses}
        keyExtractor={item => item.code}
        contentContainerStyle={styles.list}
        renderItem={({ item }) => {
          const isSelected = completedCourses.includes(item.code);
          return (
            <TouchableOpacity 
              style={[styles.item, isSelected && styles.selectedItem]}
              onPress={() => toggleCourse(item.code)}
            >
              <View>
                <Text style={[styles.code, isSelected && styles.selectedText]}>{item.code}</Text>
                <Text style={[styles.name, isSelected && styles.selectedText]}>{item.name}</Text>
              </View>
              {isSelected && <Text style={styles.check}>✓</Text>}
            </TouchableOpacity>
          );
        }}
      />

      <View style={styles.footer}>
        <Text style={styles.counter}>{completedCourses.length} courses selected</Text>
        <TouchableOpacity style={styles.button} onPress={handleNext}>
          <Text style={styles.buttonText}>Next: Current Enrollment</Text>
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
    backgroundColor: '#fff',
    borderWidth: 1,
    borderColor: '#eee',
    marginBottom: 8,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  selectedItem: {
    backgroundColor: '#E8F5E9',
    borderColor: '#4CAF50',
  },
  code: {
    fontWeight: 'bold',
    fontSize: 16,
    color: '#333',
    marginBottom: 2,
  },
  name: {
    fontSize: 14,
    color: '#666',
  },
  selectedText: {
    color: '#2E7D32',
  },
  check: {
    color: '#4CAF50',
    fontSize: 18,
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
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  counter: {
    fontSize: 14,
    color: '#666',
    fontWeight: '600',
  },
  button: {
    backgroundColor: '#007AFF',
    paddingVertical: 12,
    paddingHorizontal: 24,
    borderRadius: 24,
  },
  buttonText: {
    color: '#fff',
    fontWeight: 'bold',
  },
});

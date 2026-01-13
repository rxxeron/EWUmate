import React, { useState } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ScrollView, Alert } from 'react-native';
import { useRouter } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';
import { auth, db } from '../../firebaseConfig';
import { doc, updateDoc, getDoc } from 'firebase/firestore';

type Program = {
  id: string;
  name: string;
};

type Department = {
  name: string;
  programs: Program[];
};

const LOCAL_DEPARTMENTS: Department[] = [];

export default function ProgramSelection() {
  const router = useRouter();
  const [selectedProgram, setSelectedProgram] = useState(null as string | null);
  const [saving, setSaving] = useState(false);
  const [departments, setDepartments] = useState<Department[]>(LOCAL_DEPARTMENTS);

  React.useEffect(() => {
    fetchDepartments();
  }, []);

  const fetchDepartments = async () => {
    try {
      const docRef = doc(db, 'metadata', 'departments');
      const snap = await getDoc(docRef);
      if (snap.exists() && snap.data().list) {
        setDepartments(snap.data().list);
      }
    } catch (e) {
      console.log('Using local department list');
    }
  };

  const handleSelect = async (programId: string) => {
    setSelectedProgram(programId);
    setSaving(true);
    
    // Find department name for context
    let deptName = "";
    departments.forEach(d => {
        if(d.programs.find(p => p.id === programId)) deptName = d.name;
    });

    const user = auth.currentUser;
    if (user) {
        try {
            await updateDoc(doc(db, "users", user.uid), {
                program: programId,
                department: deptName
            });
            
            // Artificial delay for feedback
            setTimeout(() => {
                setSaving(false);
                router.push('/onboarding/course-history');
            }, 500);
        } catch (error) {
            setSaving(false);
            Alert.alert("Error saving selection", "Please try again");
        }
    } else {
        // Fallback for dev/demo if auth lost
        setTimeout(() => {
            setSaving(false);
            router.push('/onboarding/course-history');
        }, 500);
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      <Text style={styles.title}>Select Your Program</Text>
      <Text style={styles.subtitle}>Choose your department and program</Text>

      {saving && (
        <View style={styles.savingOverlay}>
            <Text style={styles.savingText}>Saving...</Text>
        </View>
      )}

      <ScrollView contentContainerStyle={styles.scrollContent}>
        {departments.map((dept, index) => {
          // @ts-ignore
          return (
            <View key={index} style={styles.section}>
              <Text style={styles.sectionTitle}>{dept.name}</Text>
              {dept.programs.map((prog) => (
                <TouchableOpacity
                  key={prog.id}
                  style={[
                    styles.card,
                    selectedProgram === prog.id && styles.selectedCard
                  ]}
                  onPress={() => handleSelect(prog.id)}
                >
                  <Text style={[
                      styles.cardText,
                      selectedProgram === prog.id && styles.selectedCardText
                  ]}>{prog.name}</Text>
                  {selectedProgram === prog.id && <Text style={styles.checkmark}>✓</Text>}
                </TouchableOpacity>
              ))}
            </View>
          );
        })}
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
  },
  scrollContent: {
    padding: 20,
    paddingBottom: 40,
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    marginBottom: 8,
    color: '#333',
    textAlign: 'center',
  },
  subtitle: {
    fontSize: 16,
    color: '#666',
    textAlign: 'center',
    marginBottom: 24,
  },
  section: {
    marginBottom: 24,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#444',
    marginBottom: 12,
    marginLeft: 4,
  },
  card: {
    backgroundColor: '#f9f9f9',
    padding: 18,
    borderRadius: 12,
    marginBottom: 10,
    borderWidth: 1,
    borderColor: '#eee',
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  selectedCard: {
    backgroundColor: '#E3F2FD',
    borderColor: '#2196F3',
  },
  cardText: {
    fontSize: 16,
    color: '#333',
  },
  selectedCardText: {
    color: '#0D47A1',
    fontWeight: '500',
  },
  checkmark: {
    color: '#2196F3',
    fontWeight: 'bold',
    fontSize: 18,
  },
  savingOverlay: {
    position: 'absolute',
    top: 0, 
    left: 0, 
    right: 0,
    zIndex: 10,
    backgroundColor: 'rgba(255,255,255,0.9)',
    alignItems: 'center',
    justifyContent: 'center',
    padding: 10,
  },
  savingText: {
    color: '#2196F3',
    fontWeight: 'bold',
  }
});

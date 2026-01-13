import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, FlatList, TouchableOpacity, ScrollView, Animated, Dimensions } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { db, auth } from '../../firebaseConfig';
import { doc, getDoc } from 'firebase/firestore';
import { Ionicons } from '@expo/vector-icons';
import CourseBrowser from '../../components/CourseBrowser';

export default function CoursesScreen() {
  const [activeTab, setActiveTab] = useState('enrolled'); // 'enrolled' | 'completed'
  const [showAddModal, setShowAddModal] = useState(false);
  const [userData, setUserData] = useState({ enrolled: [], completed: [] });
  const [loading, setLoading] = useState(true);

  // For nice sliding animation
  const [slideAnim] = useState(new Animated.Value(0));

  useEffect(() => {
    fetchMyCourses();
  }, [showAddModal]); // Refetch when modal closes

  const fetchMyCourses = async () => {
    try {
      const user = auth.currentUser;
      if (!user) return;
      const userRef = doc(db, 'users', user.uid);
      const snap = await getDoc(userRef);
      if (snap.exists()) {
          const data = snap.data();
          setUserData({
              enrolled: data.enrolledSections || [],
              completed: data.completedCourses || []
          });
      }
    } catch (e) {
        console.log("Error fetching courses", e);
    } finally {
        setLoading(false);
    }
  };

  const getDisplayCode = (id) => {
      if (!id) return "";
      const parts = id.split('_');
      // New Format: Spring2026_CSE101_1 -> CSE101
      if (parts.length === 3) return parts[1];
      // Old Format: CSE101_1 -> CSE101
      return parts[0];
  };

  const switchTab = (tab) => {
      setActiveTab(tab);
      Animated.spring(slideAnim, {
          toValue: tab === 'enrolled' ? 0 : 1,
          useNativeDriver: true,
          tension: 60,
          friction: 7
      }).start();
  };

  const renderEnrolledItem = ({ item }) => (
    <View style={styles.card}>
        <View style={styles.cardLeft}>
            <View style={styles.iconBox}>
                <Ionicons name="book-outline" size={24} color="#4F46E5" />
            </View>
        </View>
        <View style={styles.cardBody}>
            <Text style={styles.courseCode}>{getDisplayCode(item)}</Text>
            <Text style={styles.statusText}>Currently Enrolled</Text>
        </View>
        <View style={styles.cardRight}>
            <Ionicons name="chevron-forward" size={20} color="#ccc" />
        </View>
    </View>
  );

  const renderCompletedItem = ({ item }) => (
    <View style={[styles.card, styles.completedCard]}>
        <View style={styles.cardLeft}>
             <View style={[styles.iconBox, styles.completedIconBox]}>
                <Ionicons name="checkmark-circle" size={24} color="#059669" />
            </View>
        </View>
        <View style={styles.cardBody}>
            <Text style={[styles.courseCode, styles.completedCode]}>{getDisplayCode(item)}</Text>
            <Text style={styles.completedStatus}>Completed</Text>
        </View>
    </View>
  );

  return (
    <SafeAreaView style={styles.container} edges={['top']}>
      
      {/* Header */}
      <View style={styles.header}>
          <Text style={styles.headerTitle}>My Courses</Text>
          <TouchableOpacity style={styles.addButton} onPress={() => setShowAddModal(true)}>
              <Ionicons name="add" size={24} color="#fff" />
          </TouchableOpacity>
      </View>

      {/* Tabs */}
      <View style={styles.tabContainer}>
          <View style={styles.tabBackground}>
              <Animated.View style={[
                  styles.activeIndicator, 
                  {
                      transform: [{
                          translateX: slideAnim.interpolate({
                              inputRange: [0, 1],
                              outputRange: [2, (Dimensions.get('window').width - 32) / 2 - 2]
                          })
                      }]
                  }
              ]} />
              <TouchableOpacity style={styles.tabButton} onPress={() => switchTab('enrolled')}>
                  <Text style={[styles.tabText, activeTab === 'enrolled' && styles.activeTabText]}>Enrolled</Text>
              </TouchableOpacity>
              <TouchableOpacity style={styles.tabButton} onPress={() => switchTab('completed')}>
                  <Text style={[styles.tabText, activeTab === 'completed' && styles.activeTabText]}>Completed</Text>
              </TouchableOpacity>
          </View>
      </View>

      {/* Content */}
      <ScrollView contentContainerStyle={styles.content}>
          <View style={styles.summaryContainer}>
              <Text style={styles.summaryText}>
                  {activeTab === 'enrolled' 
                    ? `You are taking ${userData.enrolled.length} courses this semester.` 
                    : `You have completed ${userData.completed.length} courses total.`}
              </Text>
          </View>

          {activeTab === 'enrolled' ? (
              <FlatList 
                data={userData.enrolled}
                renderItem={renderEnrolledItem}
                keyExtractor={i => i}
                scrollEnabled={false}
                ListEmptyComponent={<Text style={styles.emptyText}>No enrolled courses.</Text>}
              />
          ) : (
             <FlatList 
                data={userData.completed}
                renderItem={renderCompletedItem}
                keyExtractor={i => i}
                scrollEnabled={false}
                ListEmptyComponent={<Text style={styles.emptyText}>No completed courses.</Text>}
              />
          )}
      </ScrollView>

      {/* Browser Modal */}
      <CourseBrowser visible={showAddModal} onClose={() => setShowAddModal(false)} />

    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F9FAFB',
  },
  header: {
      flexDirection: 'row',
      justifyContent: 'space-between',
      alignItems: 'center',
      paddingHorizontal: 20,
      paddingVertical: 16,
      backgroundColor: '#fff',
  },
  headerTitle: {
      fontSize: 24,
      fontWeight: '800',
      color: '#111',
  },
  addButton: {
      backgroundColor: '#4F46E5',
      width: 40,
      height: 40,
      borderRadius: 20,
      alignItems: 'center',
      justifyContent: 'center',
      shadowColor: '#4F46E5',
      shadowOffset: {width:0, height:4},
      shadowOpacity: 0.3,
      shadowRadius: 6,
  },
  tabContainer: {
      paddingHorizontal: 16,
      marginTop: 8,
      marginBottom: 8,
  },
  tabBackground: {
      flexDirection: 'row',
      backgroundColor: '#E5E7EB',
      borderRadius: 12,
      height: 46,
      position: 'relative',
      padding: 2,
  },
  activeIndicator: {
      position: 'absolute',
      width: '50%',
      height: '100%',
      backgroundColor: '#fff',
      borderRadius: 10,
      top: 2,
      shadowColor: '#000',
      shadowOpacity: 0.1,
      shadowRadius: 2,
      elevation: 2,
  },
  tabButton: {
      flex: 1,
      alignItems: 'center',
      justifyContent: 'center',
      zIndex: 1,
  },
  tabText: {
      fontWeight: '600',
      color: '#6B7280',
      fontSize: 14,
  },
  activeTabText: {
      color: '#111',
      fontWeight: '700',
  },
  content: {
      padding: 16,
  },
  summaryContainer: {
      marginBottom: 16,
  },
  summaryText: {
      color: '#6B7280',
      fontSize: 14,
  },
  card: {
      backgroundColor: '#fff',
      borderRadius: 16,
      padding: 16,
      marginBottom: 12,
      flexDirection: 'row',
      alignItems: 'center',
      shadowColor: '#000',
      shadowOpacity: 0.05,
      shadowRadius: 8,
      elevation: 1,
      borderLeftWidth: 4,
      borderLeftColor: '#4F46E5',
  },
  completedCard: {
      borderLeftColor: '#059669',
  },
  cardLeft: {
      marginRight: 16,
  },
  iconBox: {
      width: 44,
      height: 44,
      borderRadius: 12,
      backgroundColor: '#EEF2FF',
      alignItems: 'center',
      justifyContent: 'center',
  },
  completedIconBox: {
      backgroundColor: '#D1FAE5',
  },
  cardBody: {
      flex: 1,
  },
  courseCode: {
      fontSize: 18,
      fontWeight: '700',
      color: '#1F2937',
      marginBottom: 2,
  },
  completedCode: {
      color: '#065F46',
  },
  statusText: {
      fontSize: 12,
      color: '#6366F1',
      fontWeight: '500',
  },
  completedStatus: {
      fontSize: 12,
      color: '#059669',
      fontWeight: '500',
  },
  cardRight: {
      marginLeft: 8,
  },
  emptyText: {
      textAlign: 'center',
      color: '#999',
      marginTop: 20,
      fontStyle: 'italic',
  }
});

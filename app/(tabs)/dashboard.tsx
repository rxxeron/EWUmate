// See https://docs.expo.dev/router/introduction/
import React, { useContext, useState } from 'react';
import { router } from 'expo-router';
import { View, Text, FlatList, StyleSheet, ActivityIndicator, StatusBar, Image, TextInput, ScrollView, TouchableOpacity, Alert } from 'react-native';
import { useDashboardSchedule } from '../../hooks/useDashboardSchedule';
import { CourseContext } from '../../context/CourseContext';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { formatDistanceToNow, isPast, parseISO } from 'date-fns';
import * as Haptics from 'expo-haptics';
import { LinearGradient } from 'expo-linear-gradient';
import Animated, { FadeInDown, FadeInUp } from 'react-native-reanimated';
import TaskModal from '../../components/TaskModal';
import LottieView from 'lottie-react-native';
import { useTheme } from '../../context/ThemeContext';
import { ScheduleCard } from '../../components/Dashboard/ScheduleCard';
import { TaskCard } from '../../components/Dashboard/TaskCard';

// Define explicit types to fix "implicit any" errors
interface ScheduleItem {
  id: string;
  courseName: string;
  code: string;
  docId?: string;
  room?: string;
  startTime: string;
  endTime: string;
  [key: string]: any;
}

interface TaskItem {
    id: string;
    courseId: string;
    type: string;
    dueDate: string;
    description: string;
    status: string;
    [key: string]: any;
}

export default function DashboardScreen() {
  const { schedules: enrolledCourses, tasks, holidays, loading, user } = useContext(CourseContext);
  const { theme, toggleTheme } = useTheme();
  const [searchQuery, setSearchQuery] = useState('');
  const [showTaskModal, setShowTaskModal] = useState(false);
  
  // Cast the hook return to any to bypass the missing TS definition
  const { scheduleForDisplay, status, targetDateDisplay, holidayReason } = useDashboardSchedule(enrolledCourses, holidays) as any;

  const getGreetingData = () => {
    const hour = new Date().getHours();
    // Logic adapted for available assets: Sun, Cloud, Moon
    if (hour < 5) return { text: "Good Night 🌙", anim: require('../../assets/moon.json') };
    if (hour < 12) return { text: "Good Morning ☀️", anim: require('../../assets/sun.json') };
    if (hour < 17) return { text: "Good Afternoon 🌤️", anim: require('../../assets/cloud.json') };
    // Use Moon for Evening/Night as fallback for Sunset
    return { text: "Good Evening 🌙", anim: require('../../assets/moon.json') }; 
  };

  const getDisplayName = () => {
      if (!user?.fullName) return "Student";
      const name = user.fullName;
      const cleanName = name.replace(/^(Md\.?|Mr\.?|Mrs\.?|Ms\.?)\s+/i, "");
      return cleanName.split(' ')[0];
  };

  const greetingData = getGreetingData();

  const filteredSchedule = (scheduleForDisplay || []).filter((item: ScheduleItem) => {
    if (!searchQuery) return true;
    const q = searchQuery.toLowerCase();
    return (
      item.courseName?.toLowerCase().includes(q) ||
      (item.code || item.docId)?.toLowerCase().includes(q) ||
      item.room?.toLowerCase().includes(q)
    );
  });

  return (
    <View style={[styles.container, { backgroundColor: theme.colors.background }]}>
      <StatusBar barStyle={theme.dark ? "light-content" : "dark-content"} backgroundColor={theme.colors.background} />
      
      {/* Header Section */}
      <View style={{zIndex: 10}}>
        <LinearGradient
            colors={theme.dark ? [theme.colors.background, theme.colors.background] : ['#ffffff', '#f3f4f6']}
            start={{ x: 0, y: 0 }}
            end={{ x: 0, y: 1 }}
        >
            <View style={[styles.header, { backgroundColor: 'transparent', borderBottomWidth: 0 }]}>
                <View style={{flexDirection: 'row', alignItems: 'center'}}>
                     <View>
                        <Text style={[styles.subGreeting, { color: theme.colors.subtext }]}>{targetDateDisplay.toUpperCase()}</Text>
                        <View style={{flexDirection: 'row', alignItems: 'center'}}>
                            <Text style={[styles.greeting, { color: theme.colors.subtext }]}>
                                {greetingData.text}, {getDisplayName()}
                            </Text>
                            <LottieView
                                autoPlay
                                loop={false}
                                style={{
                                    width: 40,
                                    height: 40,
                                    marginLeft: 8
                                }}
                                source={greetingData.anim}
                            />
                        </View>
                    </View>
                </View>
                <View style={{flexDirection: 'row', gap: 10}}>
                <TouchableOpacity 
                    onPress={() => {
                        Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
                        toggleTheme();
                    }}
                    style={[styles.themeButton, { backgroundColor: theme.colors.card }]}
                >
                    <Ionicons 
                        name={theme.dark ? "sunny" : "moon"} 
                        size={20} 
                        color={theme.colors.text} 
                    />
                </TouchableOpacity>
                <TouchableOpacity 
                    onPress={() => {
                        Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Soft);
                        router.push('/profile');
                    }}
                    style={[styles.themeButton, { backgroundColor: theme.colors.card }]}
                >
                    <Ionicons 
                        name="person" 
                        size={20} 
                        color={theme.colors.text} 
                    />
                </TouchableOpacity>
                </View>
            </View>
        </LinearGradient>
      </View>

      {/* Search Bar */}
      <View style={[styles.searchContainer, { backgroundColor: theme.colors.card, borderBottomColor: theme.colors.border }]}>
        <TextInput 
          style={[styles.searchInput, { backgroundColor: theme.colors.background, color: theme.colors.text }]}
          placeholder="Search classes..."
          placeholderTextColor={theme.colors.subtext}
          value={searchQuery}
          onChangeText={setSearchQuery}
        />
      </View>

      {/* Stats / Status Bar */}
      {!loading && status === 'subsequent' && (
        <View style={styles.statusRow}>
           <Text style={[styles.statusText, { color: theme.colors.subtext }]}>
             You have <Text style={{fontWeight:'800', color: theme.colors.primary}}>{scheduleForDisplay.length}</Text> classes coming up.
           </Text>
        </View>
      )}

      <ScrollView contentContainerStyle={styles.listContent}>
          {/* Classes Section */}
          <Text style={[styles.sectionTitle, { color: theme.colors.text }]}>Classes</Text>
          
          {loading ? (
             <View style={styles.centerContainer}>
               <ActivityIndicator size="large" color={theme.colors.primary} />
               <Text style={[styles.loadingText, { color: theme.colors.subtext }]}>Fetching Schedule...</Text>
             </View>
          ) : status === 'holiday' ? (
            <View style={styles.heroContainer}>
              <View style={[
                  styles.heroCard, 
                  { backgroundColor: theme.dark ? '#372020' : '#FEF2F2', borderColor: theme.dark ? '#7f1d1d' : '#FECACA' }
                ]}>
                <Text style={styles.heroEmoji}>🎉</Text>
                <Text style={[styles.heroTitle, { color: '#DC2626' }]}>Holiday!</Text>
                <Text style={[styles.heroSubtitle, { color: theme.colors.text }]}>{holidayReason}</Text>
                <Text style={[styles.heroDesc, { color: theme.colors.subtext }]}>Enjoy your day off. No classes scheduled.</Text>
              </View>
            </View>
          ) : status === 'chill' ? (
            <View style={styles.heroContainer}>
              <View style={[
                  styles.heroCard, 
                  { backgroundColor: theme.dark ? '#064e3b' : '#ECFDF5', borderColor: theme.dark ? '#065f46' : '#A7F3D0' }
                ]}>
                <Text style={styles.heroEmoji}>☕</Text>
                <Text style={[styles.heroTitle, { color: '#059669' }]}>Chill Mode</Text>
                <Text style={[styles.heroSubtitle, { color: theme.colors.text }]}>You're all done!</Text>
                <Text style={[styles.heroDesc, { color: theme.colors.subtext }]}>No more classes for this day. Time to relax or study.</Text>
              </View>
            </View>
          ) : (
             filteredSchedule.map((item: ScheduleItem, index: number) => (
                 <View key={`${item.docId || index}`}>
                    <ScheduleCard item={item} index={index} />
                 </View>
             ))
          )}

          {/* Tasks Section */}
          <View style={styles.sectionHeader}>
             <Text style={[styles.sectionTitle, { color: theme.colors.text }]}>Tasks & Progress</Text>
             <TouchableOpacity onPress={() => {
                 Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
                 setShowTaskModal(true);
             }}>
                 <Ionicons name="add-circle" size={28} color={theme.colors.primary} />
             </TouchableOpacity>
          </View>

          {tasks && tasks.length > 0 ? (
              tasks.map((task: TaskItem, index: number) => <TaskCard key={task.id || index} task={task} index={index} />)
          ) : (
              <View style={[styles.emptyTaskBox, { backgroundColor: theme.colors.card, borderColor: theme.colors.border }]}>
                  <Text style={[styles.emptyTaskText, { color: theme.colors.subtext }]}>No upcoming tasks</Text>
                  <TouchableOpacity onPress={() => {
                      Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
                      setShowTaskModal(true);
                  }}>
                      <Text style={[styles.addTaskLink, { color: theme.colors.primary }]}>+ Add Task</Text>
                  </TouchableOpacity>
              </View>
          )}

          {/* Spacer */}
          <View style={{height: 40}} />
      </ScrollView>

      <TaskModal 
        visible={showTaskModal} 
        onClose={() => setShowTaskModal(false)} 
        courses={enrolledCourses}
        onSave={(data: any) => console.log('Task saved', data)} 
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  searchContainer: {
    paddingHorizontal: 24,
    paddingVertical: 12,
    borderBottomWidth: 1,
  },
  searchInput: {
    borderRadius: 12,
    paddingHorizontal: 16,
    paddingVertical: 10,
    fontSize: 16,
  },
  header: {
    paddingHorizontal: 24,
    paddingVertical: 20,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    borderBottomWidth: 1,
    borderBottomColor: '#E5E7EB',
  },
  subGreeting: {
    fontSize: 13,
    fontWeight: '700',
    letterSpacing: 1,
    marginBottom: 4,
  },
  themeButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    alignItems: 'center',
    justifyContent: 'center',
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  greeting: {
    fontSize: 20, // Smaller "Good Morning"
    fontWeight: '600',
    color: '#6B7280',
    letterSpacing: -0.5,
  },
  statusRow: {
    paddingHorizontal: 24,
    paddingVertical: 12,
  },
  statusText: {
    fontSize: 15,
    fontWeight: '500',
  },
  listContent: {
    padding: 24,
    paddingTop: 12,
  },
  centerContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  loadingText: {
    marginTop: 12,
    fontSize: 16,
    fontWeight: '500',
  },
  heroContainer: {
    flex: 1,
    padding: 24,
    justifyContent: 'center',
  },
  heroCard: {
    padding: 32,
    borderRadius: 24,
    alignItems: 'center',
    borderWidth: 1,
  },
  heroEmoji: {
    fontSize: 64,
    marginBottom: 16,
  },
  heroTitle: {
    fontSize: 24,
    fontWeight: '900',
    marginBottom: 8,
  },
  heroSubtitle: {
    fontSize: 18,
    fontWeight: '600',
    marginBottom: 12,
  },
  heroDesc: {
    textAlign: 'center',
    fontSize: 15,
    lineHeight: 22,
  },
  sectionHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12, marginTop: 24 },
  sectionTitle: { fontSize: 20, fontWeight: '800', marginBottom: 12 },
  emptyTaskBox: { padding: 20, alignItems: 'center', borderRadius: 12, borderStyle: 'dashed', borderWidth: 1 },
  emptyTaskText: { marginBottom: 8 },
  addTaskLink: { fontWeight: 'bold' }
});

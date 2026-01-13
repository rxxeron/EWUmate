import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import Animated, { FadeInDown } from 'react-native-reanimated';
import { LinearGradient } from 'expo-linear-gradient';
import { useTheme } from '../../context/ThemeContext';

interface ScheduleCardProps {
  item: any;
  index: number;
}

const getDeptColor = (dept: string) => {
  if (!dept) return '#6B7280';
  if (dept.includes('CSE')) return '#4F46E5'; // Indigo
  if (dept.includes('MPS')) return '#9333EA'; // Purple
  if (dept.includes('ENG')) return '#EA580C'; // Orange
  if (dept.includes('BA')) return '#059669'; // Emerald
  return '#6B7280'; // Gray
};

export const ScheduleCard: React.FC<ScheduleCardProps> = ({ item, index }) => {
  const { theme } = useTheme();
  const accentColor = getDeptColor(item.dept);
  
  // Fallback if 'code' field doesn't exist (legacy data)
  let displayCode = item.code;
  if (!displayCode && item.docId) {
     // Old Format: CSE101_1 -> CSE101
     // New Format: Spring2026_CSE101_1 -> CSE101 (Need to parse)
     const parts = item.docId.split('_');
     if (parts.length === 3) displayCode = parts[1]; // Spring2026_CSE101_1
     else displayCode = parts[0]; // CSE101_1
  }
  
  return (
    <Animated.View 
      entering={FadeInDown.delay(100 + (index * 50)).springify()}
      style={[
        styles.card, 
        { 
          borderLeftColor: accentColor, 
          backgroundColor: theme.colors.card,
          shadowColor: theme.dark ? '#000' : '#000'
        }
      ]}
    >
      <LinearGradient
        colors={theme.dark ? [theme.colors.card, theme.colors.card] : ['#ffffff', '#fafafa']}
        style={styles.cardInternal}
      >
        <View style={styles.cardHeader}>
          <View style={[styles.tag, { backgroundColor: accentColor + '20' }]}>
             <Text style={[styles.qtText, { color: accentColor }]}>{displayCode}</Text>
          </View>
          <Text style={[styles.roomBadge, { color: theme.colors.subtext, backgroundColor: theme.colors.accent }]}>
             Room {item.room}
          </Text>
        </View>
        
        <Text style={[styles.courseTitle, { color: theme.colors.text }]} numberOfLines={2}>
          {item.courseName}
        </Text>
        
        <View style={[styles.timeContainer, { backgroundColor: theme.colors.background }]}>
           <Text style={[styles.timeIcon, { color: theme.colors.text }]}>⏰</Text>
           <Text style={[styles.timeText, { color: theme.colors.text }]}>
             {item.startTime} <Text style={{color: theme.colors.subtext}}>to</Text> {item.endTime}
           </Text>
        </View>
      </LinearGradient>
    </Animated.View>
  );
};

const styles = StyleSheet.create({
  card: {
    borderRadius: 20,
    marginBottom: 16,
    borderLeftWidth: 6,
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.05,
    shadowRadius: 12,
    elevation: 3,
    overflow: 'hidden',
  },
  cardInternal: {
    padding: 20,
  },
  cardHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 12,
  },
  tag: {
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 8,
  },
  qtText: {
    fontSize: 12,
    fontWeight: '800',
    letterSpacing: 0.5,
  },
  roomBadge: {
    fontSize: 13,
    fontWeight: '600',
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderRadius: 6,
    overflow: 'hidden',
  },
  courseTitle: {
    fontSize: 20,
    fontWeight: '700',
    marginBottom: 16,
    lineHeight: 28,
  },
  timeContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 10,
    borderRadius: 12,
  },
  timeIcon: {
    fontSize: 16,
    marginRight: 8,
  },
  timeText: {
    fontSize: 16,
    fontWeight: '700',
  },
});

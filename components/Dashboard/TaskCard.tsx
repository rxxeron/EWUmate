import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import Animated, { FadeInDown } from 'react-native-reanimated';
import { Ionicons } from '@expo/vector-icons';
import { formatDistanceToNow, isPast, parseISO } from 'date-fns';
import { useTheme } from '../../context/ThemeContext';

interface TaskCardProps {
  task: any;
  index: number;
}

export const TaskCard: React.FC<TaskCardProps> = ({ task, index }) => {
    const { theme } = useTheme();

    const getTaskNotification = (task: any) => {
        const type = (task.type || "").toLowerCase();
        if (type.includes('presentation')) return { msg: "Be well prepared! Dress sharply.", color: '#EA580C', icon: 'mic-outline' as const };
        if (type.includes('quiz') || type.includes('viva')) return { msg: "Review your notes. Be ready!", color: '#DC2626', icon: 'help-circle-outline' as const };
        if (type.includes('assignment')) {
            // Check if due soon (e.g. < 24 hours)
            if (task.dueDate) {
                const due = parseISO(task.dueDate);
                const diffHours = (due.getTime() - new Date().getTime()) / 36e5; // hours
                if (diffHours < 24 && diffHours > 0) return { msg: "Last moment check! Submit properly.", color: '#F59E0B', icon: 'alert-circle-outline' as const };
            }
            return { msg: "Don't forget to submit.", color: '#4F46E5', icon: 'document-text-outline' as const };
        }
        return { msg: "Upcoming Event", color: '#4B5563', icon: 'calendar-outline' as const };
    };

    const { msg, color, icon } = getTaskNotification(task);
    const isOverdue = task.dueDate ? isPast(parseISO(task.dueDate)) : false;
    const timeLeft = task.dueDate 
        ? (isOverdue ? "Overdue" : formatDistanceToNow(parseISO(task.dueDate), { addSuffix: true }))
        : "No date";

    return (
        <Animated.View 
            entering={FadeInDown.delay(200 + (index * 50)).springify()}
            style={[
                styles.taskCard, 
                { 
                    borderLeftColor: color,
                    backgroundColor: theme.colors.card,
                    shadowColor: theme.dark ? '#000' : '#000'
                }
            ]}
        >
            <View style={styles.taskHeader}>
                <Text style={[styles.taskType, { color }]}>{task.type}</Text>
                <Text style={[styles.taskTime, { color: theme.colors.subtext }]}>{timeLeft}</Text>
            </View>
            <Text style={[styles.taskCourse, { color: theme.colors.text }]}>
                {task.courseCode} - {task.courseName}
            </Text>
            {task.description ? <Text style={[styles.taskDesc, { color: theme.colors.subtext }]}>{task.description}</Text> : null}
            
            <View style={[styles.notificationBox, { backgroundColor: color + '15' }]}>
                <Ionicons name={icon} size={16} color={color} style={{marginRight: 6}} />
                <Text style={[styles.notificationText, { color }]}>{msg}</Text>
            </View>
        </Animated.View>
    );
};

const styles = StyleSheet.create({
  taskCard: { 
    borderRadius: 16, 
    padding: 16, 
    marginBottom: 12, 
    borderLeftWidth: 4, 
    elevation: 2, 
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05, 
    shadowRadius: 6 
  },
  taskHeader: { flexDirection: 'row', justifyContent: 'space-between', marginBottom: 8 },
  taskType: { fontSize: 12, fontWeight: '700', textTransform: 'uppercase' },
  taskTime: { fontSize: 12 },
  taskCourse: { fontSize: 16, fontWeight: '700', marginBottom: 4 },
  taskDesc: { fontSize: 14, marginBottom: 12 },
  notificationBox: { flexDirection: 'row', alignItems: 'center', padding: 10, borderRadius: 8 },
  notificationText: { fontSize: 13, fontWeight: '600' },
});

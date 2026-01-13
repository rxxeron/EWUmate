import { Tabs } from 'expo-router';
import { Platform } from 'react-native';

export default function TabsLayout() {
  return (
    <Tabs
      screenOptions={{
        headerShown: false,
        tabBarStyle: {
          height: Platform.OS === 'ios' ? 88 : 60,
          paddingBottom: Platform.OS === 'ios' ? 28 : 8,
          paddingTop: 8,
          backgroundColor: '#FFFFFF',
          borderTopWidth: 1,
          borderTopColor: '#E5E5E5',
        },
        tabBarActiveTintColor: '#4A90E2',
        tabBarInactiveTintColor: '#999',
      }}
    >
      <Tabs.Screen 
        name="dashboard" 
        options={{ 
          title: 'Dashboard',
          tabBarLabel: 'Home',
          // You can add tabBarIcon here later
        }} 
      />
      <Tabs.Screen 
        name="planner" 
        options={{ 
          title: 'Advising',
          tabBarLabel: 'Planner',
          // You can add tabBarIcon here later
        }} 
      />
      <Tabs.Screen 
        name="courses" 
        options={{ 
          title: 'Courses',
          tabBarLabel: 'My Courses',
          // You can add tabBarIcon here later
        }} 
      />
      <Tabs.Screen 
        name="results" 
        options={{ 
          title: 'Records',
          tabBarLabel: 'Results',
          // You can add tabBarIcon here later
        }} 
      />
    </Tabs>
  );
}

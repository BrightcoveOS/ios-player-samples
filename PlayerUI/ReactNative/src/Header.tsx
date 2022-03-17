import React from 'react';
import { View, Text, StyleSheet } from 'react-native';

interface Props {
  title: string;
  subtitle: string;
}

const Header: React.FC<Props> = ({ title, subtitle }) => {
  return (
    <View style={styles.header}>
      <Text style={styles.headerText}>{title}</Text>
      <Text style={styles.subtitleText}>{subtitle}</Text>
    </View>
  );
};

const styles = StyleSheet.create({
  header: {
    backgroundColor: 'rgb(103, 58, 183)',
    paddingVertical: 20,
    alignItems: 'center',
  },
  headerText: {
    fontSize: 25,
    fontWeight: '600',
    color: 'white',
  },
  subtitleText: {
    fontSize: 20,
    fontWeight: '400',
    color: 'white',
  }
});

export default Header;

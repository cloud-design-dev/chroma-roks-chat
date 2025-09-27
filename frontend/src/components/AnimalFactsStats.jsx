import React from 'react';
import { Tile } from '@carbon/react';

// Animal emoji mapping for visual appeal
const animalEmojis = {
  'lion': '🦁',
  'elephant': '🐘', 
  'dolphin': '🐬',
  'penguin': '🐧',
  'octopus': '🐙',
  'bear': '🐻',
  'whale': '🐋',
  'tiger': '🐅',
  'shark': '🦈'
};

const AnimalFactsStats = ({ stats }) => {
  const totalFacts = Object.values(stats).reduce((sum, count) => sum + count, 0);
  
  return (
    <Tile>
      <h3>🏛️ Animal Facts Database</h3>
      <p>Total facts stored: <strong>{totalFacts}</strong></p>
      
      {Object.keys(stats).length > 0 ? (
        <div>
          <h4>📊 Facts by Animal:</h4>
          {Object.entries(stats)
            .sort(([,a], [,b]) => b - a)
            .map(([animal, count]) => (
              <div key={animal} style={{ 
                marginBottom: '0.5rem',
                display: 'flex',
                alignItems: 'center',
                gap: '0.5rem'
              }}>
                <span style={{ fontSize: '1.2em' }}>
                  {animalEmojis[animal] || '🐾'}
                </span>
                <span style={{ textTransform: 'capitalize', fontWeight: 'bold' }}>
                  {animal}:
                </span>
                <span>{count} facts</span>
              </div>
            ))}
        </div>
      ) : (
        <p style={{ fontStyle: 'italic', color: '#6f6f6f' }}>
          🚫 No facts in database yet
        </p>
      )}
      
      <div style={{ marginTop: '1rem', fontSize: '0.875rem', color: '#6f6f6f' }}>
        📈 This counter visualizes database state during Kasten backup/restore demos
      </div>
    </Tile>
  );
};

export default AnimalFactsStats;
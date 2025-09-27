import React, { useState, useEffect } from 'react';
import {
  Header,
  HeaderName,
  Content,
  Grid,
  Column,
  Tile,
  TextInput,
  TextArea,
  Button,
  Loading,
  InlineNotification,
  Modal
} from '@carbon/react';
import { Send, Add } from '@carbon/icons-react';
import AnimalFactsStats from './components/AnimalFactsStats';

function App() {
  const [query, setQuery] = useState('');
  const [response, setResponse] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [stats, setStats] = useState({});
  
  // Add fact modal state
  const [showAddModal, setShowAddModal] = useState(false);
  const [newAnimal, setNewAnimal] = useState('');
  const [newFact, setNewFact] = useState('');
  const [addingFact, setAddingFact] = useState(false);
  
  // Animal emoji mapping for visual appeal
  const animalEmojis = {
    'lion': '🦁', 'elephant': '🐘', 'dolphin': '🐬', 'penguin': '🐧',
    'octopus': '🐙', 'bear': '🐻', 'whale': '🐋', 'tiger': '🐅', 'shark': '🦈'
  };

  const fetchStats = async () => {
    try {
      const res = await fetch('/api/stats');
      const data = await res.json();
      setStats(data);
    } catch (err) {
      console.error('Failed to fetch stats:', err);
    }
  };
  
  const handleAddFact = async (e) => {
    e.preventDefault();
    if (!newAnimal.trim() || !newFact.trim()) return;

    setAddingFact(true);
    setError('');
    
    try {
      const res = await fetch('/api/add_fact', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ animal: newAnimal, fact: newFact }),
      });
      
      if (res.ok) {
        const data = await res.json();
        setSuccess(`Added new fact for ${newAnimal}!`);
        setNewAnimal('');
        setNewFact('');
        setShowAddModal(false);
        fetchStats(); // Refresh stats
        setTimeout(() => setSuccess(''), 3000);
      } else {
        setError('Failed to add fact');
      }
    } catch (err) {
      setError('Failed to add fact. Make sure the backend is running.');
    } finally {
      setAddingFact(false);
    }
  };
  
  // Get available animals for suggestions with emojis
  const availableAnimals = Object.keys(stats).length > 0 ? Object.keys(stats).sort() : 
    ['lion', 'elephant', 'dolphin', 'penguin', 'octopus', 'bear', 'whale', 'tiger', 'shark'];
  
  const animalSuggestions = availableAnimals.map(animal => 
    `${animalEmojis[animal] || '🐾'} ${animal.charAt(0).toUpperCase() + animal.slice(1)}`
  ).join(', ');

  useEffect(() => {
    fetchStats();
  }, []);

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!query.trim()) return;

    setLoading(true);
    setError('');
    
    try {
      const res = await fetch('/api/chat', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ query }),
      });
      
      const data = await res.json();
      setResponse(data.response);
      fetchStats(); // Refresh stats after query
    } catch (err) {
      setError('Failed to get response. Make sure the backend is running.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="App">
      <Header aria-label="Animal Facts Chat">
        <HeaderName href="#" prefix="🛡️ Kasten Demo">
          🐾 Animal Facts Chat
        </HeaderName>
      </Header>
      
      <Content>
        <Grid>
          <Column lg={8} md={6} sm={4}>
            <Tile>
              <h2>💬 Ask about animal facts!</h2>
              
              {error && (
                <InlineNotification
                  kind="error"
                  title="Error"
                  subtitle={error}
                  onCloseButtonClick={() => setError('')}
                />
              )}
              
              {success && (
                <InlineNotification
                  kind="success"
                  title="Success"
                  subtitle={success}
                  onCloseButtonClick={() => setSuccess('')}
                />
              )}
              
              <div style={{ marginBottom: '1rem' }}>
                <Button
                  kind="secondary"
                  renderIcon={Add}
                  onClick={() => setShowAddModal(true)}
                >
                  ➕ Add New Fact
                </Button>
              </div>
              
              <form onSubmit={handleSubmit}>
                <TextInput
                  id="query"
                  labelText="🤔 Your question"
                  placeholder="Tell me about lions... 🦁"
                  value={query}
                  onChange={(e) => setQuery(e.target.value)}
                  disabled={loading}
                />
                <Button
                  type="submit"
                  disabled={loading || !query.trim()}
                  renderIcon={Send}
                  style={{ marginTop: '1rem' }}
                >
                  {loading ? '🔍 Asking...' : '🚀 Ask'}
                </Button>
              </form>
              
              {loading && <Loading description="🔍 Getting animal facts..." />}
              
              {response && (
                <div style={{ marginTop: '2rem', padding: '1rem', backgroundColor: '#f4f4f4' }}>
                  <h4>💡 Response:</h4>
                  <p style={{ whiteSpace: 'pre-wrap' }}>{response}</p>
                </div>
              )}
            </Tile>
          </Column>
          
          <Column lg={8} md={6} sm={4}>
            <AnimalFactsStats stats={stats} />
          </Column>
        </Grid>
      </Content>
      
      {/* Add Fact Modal */}
      <Modal
        open={showAddModal}
        onRequestClose={() => setShowAddModal(false)}
        modalHeading="➕ Add New Animal Fact"
        modalLabel="🛡️ Kasten Demo"
        primaryButtonText="✨ Add Fact"
        secondaryButtonText="❌ Cancel"
        onRequestSubmit={handleAddFact}
        primaryButtonDisabled={addingFact || !newAnimal.trim() || !newFact.trim()}
      >
        <p style={{ marginBottom: '1rem' }}>🎯 Add a new animal fact to the database. Perfect for demonstrating Kasten backup and restore capabilities!</p>
        
        <TextInput
          id="animal-input"
          labelText="🐾 Animal"
          placeholder="e.g., lion, elephant, tiger, giraffe..."
          helperText={`Available: ${animalSuggestions}`}
          value={newAnimal}
          onChange={(e) => setNewAnimal(e.target.value.toLowerCase().trim())}
          disabled={addingFact}
        />
        
        <TextArea
          id="fact-input"
          labelText="📚 Animal Fact"
          placeholder="Enter an interesting fact about this animal..."
          value={newFact}
          onChange={(e) => setNewFact(e.target.value)}
          disabled={addingFact}
          rows={4}
          style={{ marginTop: '1rem' }}
        />
        
        {addingFact && <Loading description="✨ Adding fact..." />}
      </Modal>
    </div>
  );
}

export default App;
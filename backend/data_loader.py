import json
from pathlib import Path

# Comprehensive animal facts dataset
ANIMAL_FACTS = [
    # Lions
    {"animal": "lion", "fact": "Lions are the only cats that live in groups called prides, typically consisting of 10-15 individuals."},
    {"animal": "lion", "fact": "A lion's roar can be heard from up to 5 miles away and is used to communicate with pride members."},
    {"animal": "lion", "fact": "Female lions do most of the hunting, working together to take down prey much larger than themselves."},
    
    # Elephants
    {"animal": "elephant", "fact": "Elephants have excellent memories and can remember other elephants and locations for decades."},
    {"animal": "elephant", "fact": "An elephant's trunk contains over 40,000 muscles and can lift objects weighing up to 770 pounds."},
    {"animal": "elephant", "fact": "Elephants are one of the few animals that can recognize themselves in mirrors, showing self-awareness."},
    {"animal": "elephant", "fact": "Baby elephants are born weighing about 250 pounds and can stand within an hour of birth."},
    
    # Dolphins
    {"animal": "dolphin", "fact": "Dolphins use echolocation to navigate and hunt, sending out clicks and interpreting the returning echoes."},
    {"animal": "dolphin", "fact": "Each dolphin has a unique whistle signature that acts like a name, allowing them to identify each other."},
    {"animal": "dolphin", "fact": "Dolphins can sleep with one eye open, keeping half their brain alert for predators while resting."},
    
    # Penguins
    {"animal": "penguin", "fact": "Emperor penguins can dive up to 1,800 feet deep and hold their breath for up to 22 minutes."},
    {"animal": "penguin", "fact": "Penguins have excellent underwater vision and can see clearly both above and below water."},
    {"animal": "penguin", "fact": "Male emperor penguins incubate eggs on their feet for 64 days during Antarctic winter without eating."},
    
    # Octopus
    {"animal": "octopus", "fact": "Octopi have three hearts: two pump blood to the gills, and one pumps blood to the rest of the body."},
    {"animal": "octopus", "fact": "Octopi are masters of camouflage, able to change both color and texture to match their surroundings."},
    {"animal": "octopus", "fact": "Each octopus arm has its own brain, allowing them to taste and smell what they touch."},
    
    # Bears
    {"animal": "bear", "fact": "Polar bears have black skin under their white fur to absorb heat from the sun."},
    {"animal": "bear", "fact": "Grizzly bears can run up to 35 mph, faster than a human on a bicycle."},
    {"animal": "bear", "fact": "Bears have an excellent sense of smell, seven times better than a bloodhound."},
    
    # Whales
    {"animal": "whale", "fact": "Blue whales are the largest animals ever known to have lived on Earth, larger than any dinosaur."},
    {"animal": "whale", "fact": "Humpback whales create complex songs that can last up to 30 minutes and travel hundreds of miles."},
    {"animal": "whale", "fact": "Sperm whales can dive deeper than any other whale, reaching depths of over 7,000 feet."},
    
    # Tigers
    {"animal": "tiger", "fact": "Tigers are excellent swimmers and unlike most cats, they enjoy being in water."},
    {"animal": "tiger", "fact": "Each tiger has unique stripe patterns, like human fingerprints - no two tigers have identical stripes."},
    {"animal": "tiger", "fact": "Tigers can leap horizontally up to 33 feet and vertically up to 16 feet."},
    
    # Sharks
    {"animal": "shark", "fact": "Sharks have been around for more than 400 million years, predating dinosaurs by 200 million years."},
    {"animal": "shark", "fact": "Great white sharks can detect a single drop of blood in 25 gallons of water."},
    {"animal": "shark", "fact": "Sharks lose thousands of teeth throughout their lifetime and can grow new ones within days."},
]

def save_facts_to_file():
    """Save facts to JSON file for easy loading"""
    facts_file = Path(__file__).parent / "data" / "animal_facts.json"
    facts_file.parent.mkdir(exist_ok=True)
    
    with open(facts_file, "w") as f:
        json.dump(ANIMAL_FACTS, f, indent=2)

def load_facts_from_file():
    """Load facts from JSON file if it exists, otherwise return default facts"""
    facts_file = Path(__file__).parent / "data" / "animal_facts.json"
    
    if facts_file.exists():
        with open(facts_file, "r") as f:
            return json.load(f)
    
    return ANIMAL_FACTS

if __name__ == "__main__":
    save_facts_to_file()
    print(f"Saved {len(ANIMAL_FACTS)} facts to animal_facts.json")
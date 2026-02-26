local CardData = {}

-- No starter cards - player starts with $50 instead
CardData.StarterCards = {}

-- Full catalog of all cards
CardData.Cards = {
	-- =====================
	-- COMMON ($5-20 cost, $15-35 market value)
	-- =====================
	{
		id = "pikachu",
		name = "Pikachu",
		color = Color3.new(1, 0.9, 0.2),
		price = 20,
		cost = 8,
		rarity = "Common",
	},
	{
		id = "bulbasaur",
		name = "Bulbasaur",
		color = Color3.new(0.3, 0.75, 0.4),
		price = 15,
		cost = 5,
		rarity = "Common",
	},
	{
		id = "charmander",
		name = "Charmander",
		color = Color3.new(1, 0.5, 0.15),
		price = 18,
		cost = 7,
		rarity = "Common",
	},
	{
		id = "squirtle",
		name = "Squirtle",
		color = Color3.new(0.3, 0.6, 1),
		price = 15,
		cost = 5,
		rarity = "Common",
	},
	{
		id = "eevee",
		name = "Eevee",
		color = Color3.new(0.75, 0.6, 0.4),
		price = 20,
		cost = 8,
		rarity = "Common",
	},
	{
		id = "jigglypuff",
		name = "Jigglypuff",
		color = Color3.new(1, 0.7, 0.75),
		price = 12,
		cost = 4,
		rarity = "Common",
	},
	{
		id = "snorlax",
		name = "Snorlax",
		color = Color3.new(0.3, 0.35, 0.45),
		price = 25,
		cost = 10,
		rarity = "Common",
	},
	{
		id = "geodude",
		name = "Geodude",
		color = Color3.new(0.6, 0.5, 0.35),
		price = 10,
		cost = 3,
		rarity = "Common",
	},
	{
		id = "gastly",
		name = "Gastly",
		color = Color3.new(0.4, 0.2, 0.5),
		price = 18,
		cost = 7,
		rarity = "Common",
	},
	{
		id = "machop",
		name = "Machop",
		color = Color3.new(0.5, 0.55, 0.7),
		price = 12,
		cost = 4,
		rarity = "Common",
	},
	-- =====================
	-- RARE ($40-80 cost, $60-130 market value)
	-- =====================
	{
		id = "raichu",
		name = "Raichu",
		color = Color3.new(1, 0.75, 0.1),
		price = 70,
		cost = 40,
		rarity = "Rare",
	},
	{
		id = "venusaur",
		name = "Venusaur",
		color = Color3.new(0.2, 0.6, 0.35),
		price = 90,
		cost = 50,
		rarity = "Rare",
	},
	{
		id = "blastoise",
		name = "Blastoise",
		color = Color3.new(0.2, 0.4, 0.9),
		price = 100,
		cost = 55,
		rarity = "Rare",
	},
	{
		id = "gengar",
		name = "Gengar",
		color = Color3.new(0.45, 0.15, 0.55),
		price = 110,
		cost = 60,
		rarity = "Rare",
	},
	{
		id = "dragonite",
		name = "Dragonite",
		color = Color3.new(0.9, 0.65, 0.3),
		price = 130,
		cost = 75,
		rarity = "Rare",
	},
	{
		id = "gardevoir",
		name = "Gardevoir",
		color = Color3.new(0.4, 0.8, 0.6),
		price = 80,
		cost = 45,
		rarity = "Rare",
	},
	-- =====================
	-- ULTRA RARE ($150-300 cost, $250-500 market value)
	-- =====================
	{
		id = "charizard_ex",
		name = "Charizard EX",
		color = Color3.new(1, 0.4, 0),
		price = 400,
		cost = 200,
		rarity = "Ultra Rare",
	},
	{
		id = "pikachu_vmax",
		name = "Pikachu VMAX",
		color = Color3.new(1, 0.9, 0),
		price = 350,
		cost = 175,
		rarity = "Ultra Rare",
	},
	{
		id = "mewtwo_gx",
		name = "Mewtwo GX",
		color = Color3.new(0.6, 0.2, 0.8),
		price = 450,
		cost = 225,
		rarity = "Ultra Rare",
	},
	{
		id = "umbreon_vmax",
		name = "Umbreon VMAX",
		color = Color3.new(0.15, 0.15, 0.3),
		price = 500,
		cost = 250,
		rarity = "Ultra Rare",
	},
	{
		id = "mew_vmax",
		name = "Mew VMAX",
		color = Color3.new(0.9, 0.5, 0.7),
		price = 380,
		cost = 190,
		rarity = "Ultra Rare",
	},
	{
		id = "gengar_vmax",
		name = "Gengar VMAX",
		color = Color3.new(0.4, 0.1, 0.5),
		price = 300,
		cost = 150,
		rarity = "Ultra Rare",
	},
	-- =====================
	-- LEGENDARY ($500-800 cost, $700-1200 market value)
	-- =====================
	{
		id = "rayquaza_v",
		name = "Rayquaza V",
		color = Color3.new(0.2, 0.8, 0.3),
		price = 800,
		cost = 500,
		rarity = "Legendary",
	},
	{
		id = "lugia_v",
		name = "Lugia V",
		color = Color3.new(0.7, 0.75, 0.9),
		price = 900,
		cost = 550,
		rarity = "Legendary",
	},
	{
		id = "arceus_vstar",
		name = "Arceus VSTAR",
		color = Color3.new(0.9, 0.85, 0.5),
		price = 1200,
		cost = 800,
		rarity = "Legendary",
	},
	{
		id = "giratina_vstar",
		name = "Giratina VSTAR",
		color = Color3.new(0.3, 0.3, 0.35),
		price = 1000,
		cost = 600,
		rarity = "Legendary",
	},
	{
		id = "palkia_vstar",
		name = "Palkia VSTAR",
		color = Color3.new(0.55, 0.45, 0.75),
		price = 950,
		cost = 580,
		rarity = "Legendary",
	},
}

CardData.RarityColors = {
	Common = Color3.new(0.6, 0.6, 0.6),
	Rare = Color3.new(0.2, 0.5, 1),
	["Ultra Rare"] = Color3.new(0.8, 0.3, 0.9),
	Legendary = Color3.new(1, 0.8, 0.2),
}

function CardData.GetCardById(id: string)
	for _, card in CardData.Cards do
		if card.id == id then
			return card
		end
	end
	return nil
end

function CardData.GetShopCards()
	return CardData.Cards
end

return CardData

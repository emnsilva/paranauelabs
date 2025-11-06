// Mapear códigos climáticos para condições em português
const weatherCodes = {
  0: "céu limpo",
  1: "principalmente limpo", 
  2: "parcialmente nublado",
  3: "nublado",
  45: "neblina",
  48: "neblina com geada",
  51: "chuvisco leve",
  53: "chuvisco moderado",
  55: "chuvisco denso",
  56: "chuvisco congelante leve",
  57: "chuvisco congelante denso",
  61: "chuva leve",
  63: "chuva moderada",
  65: "chuva forte",
  66: "chuva congelante leve", 
  67: "chuva congelante forte",
  71: "neve leve",
  73: "neve moderada",
  75: "neve forte",
  77: "grãos de neve",
  80: "pancadas de chuva leve",
  81: "pancadas de chuva moderada",
  82: "pancadas de chuva forte",
  85: "pancadas de neve leve",
  86: "pancadas de neve forte",
  95: "trovoada leve",
  96: "trovoada com granizo leve",
  99: "trovoada com granizo forte"
};

// Extrair e formatar os dados
const rawData = $input.first().json;

const purifiedData = {
  temperatura: Math.round(rawData.current.temperature_2m),
  umidade: rawData.current.relative_humidity_2m,
  condicao: weatherCodes[rawData.current.weather_code] || "condição desconhecida",
  cidade: "Rio de Janeiro",
  timestamp: new Date().toLocaleString('pt-BR'),
  alerta: rawData.current.temperature_2m > 30 ? "ALTA_TEMPERATURA" : 
          rawData.current.relative_humidity_2m > 80 ? "ALTA_UMIDADE" : "NORMAL"
};

return purifiedData;
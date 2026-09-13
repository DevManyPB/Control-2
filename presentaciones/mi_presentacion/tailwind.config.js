/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        electricBlue: '#00e5ff',
        cyan: '#00ffff',
        accentGreen: '#39ff14',
        accentPurple: '#b026ff',
        accentOrange: '#ff6700',
        darkBg: '#0a0a0a',
        techGray: '#1e1e1e',
      }
    },
  },
  plugins: [],
}

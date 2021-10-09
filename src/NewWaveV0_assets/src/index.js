import { NewWaveV0 } from "../../declarations/NewWaveV0";

document.getElementById("clickMeBtn").addEventListener("click", async () => {
  const name = document.getElementById("name").value.toString();
  // Interact with NewWaveV0 actor, calling the greet method
  const greeting = await NewWaveV0.greet(name);

  document.getElementById("greeting").innerText = greeting;
});

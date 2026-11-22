class_name CatalogoDialogos
extends RefCounted
## Lo que dicen Don Tuerca y Calypso. {clave de tecla} se reemplaza por la tecla real del jugador.


static func dialogos() -> Dictionary:
	return {
	"inicio": [["tuerca", "¡Cabro! ¡Despertaste! Ya le había puesto precio a tus zapatos."],
		["tuerca", "Soy Don Tuerca, dueño de este basural. Te encontré tirado entre un refri y una lavadora. La lavadora estaba en mejor estado."],
		["tuerca", "¿Ves esa nave? Es tuya. Bueno, ahora es tuya. No preguntís."],
		["calypso", "Soy Calypso, la IA de la nave. Vengo incluida, como los virus."],
		["tuerca", "¡Y habla! Por eso me salió barata."],
		["tuerca", "Los robots se volvieron locos y me andan robando los fierros. Anda a dispararles, ¿ya? Si te matan, vuelves. Aquí nadie se muere de verdad: sale muy caro."]],
	"despues_1-1": [["tuerca", "¡Volviste! ¡Y con fierros! Te ganaste el cariño de este viejo."],
		["tuerca", "Te abrí el HANGAR. Ahí le pones a la nave las piezas que vayas encontrando. Antes era el baño, pero casi no se nota."],
		["calypso", "Se nota."]],
	"antes_1-2": [["tuerca", "Ojo, que ahora vienen los Rabiosos. Parpadean y se te tiran encima. Como mi ex suegra."],
		["tuerca", "Y después llegan las Moscas: chiquititas, en montón y te persiguen como cobrador. La buena: caen de un balazo."],
		["calypso", "No son moscas, son drones. Pero zumban igual de molesto."],
		["tuerca", "Si te ves apretado, aprieta {esquivar} y esquiva. ¿Cachai?"]],
	"despues_1-2": [["tuerca", "Mira lo que encontré: un reactor roto. Le pegué dos patadas y ahora hace algo rarísimo."],
		["tuerca", "Se llama DESYNC. Llenas la barra, aprietas {desync}, y tus balazos quedan colgados. Como el internet de mi casa."],
		["calypso", "Cuando reconecta, llegan todos juntos. Es mi parte favorita, y yo no tengo partes."]],
	"despues_1-3": [["tuerca", "¡Cabro, cabro, cabro! ¡Mira lo que salió de una lata de atún!"],
		["tuerca", "No sé qué es. No muerde. Bueno, muerde. Pero muerde balas: las que pasen cerca de tu nave, se las come."],
		["tuerca", "Y se come cualquier fierro. Le das tres piezas iguales en el HANGAR y te escupe una mejor. Eso es FUSIONAR. No preguntís cómo, yo tampoco quiero saber."],
		["tuerca", "Yo le diría Mordisco. Si quieres otro nombre, se lo cambias en el Hangar."],
		["calypso", "No sé qué le das de comer a esa cosa."]],
	"antes_1-4": [["tuerca", "¿Escuchas ese ruido? Es La Grúa. Lleva años levantando autos y ahora te quiere levantar a ti."],
		["tuerca", "Dispárale al núcleo rojo. Regla de oro: si tiene núcleo rojo, se rompe."]],
	"despues_1-4": [["tuerca", "¡Botaste a La Grúa! Se me cayó encima de la caseta, pero son detalles."],
		["tuerca", "Te colgué un TABLÓN en el Hangar. Ahí anoto encargos: me cumples uno y te paso un fierro nuevo. Armas, habilidades, de todo."],
		["calypso", "En el ARSENAL puedes prender o apagar lo que vayas ganando, para que solo te salgan las cartas que quieres."]],
	"antes_1-5": [["tuerca", "Esos que gritan son Spammers. Tiran burbujas de chat. ¿La buena noticia? Las burbujas se rompen a balazos."]],
	"despues_1-5": [["tuerca", "Encontré un cofre. Tenía una pieza buenaza. También tenía un mapache, pero ese se fue."],
		["calypso", "Se llevó tu billetera."]],
	"despues_1-6": [["tuerca", "Te enseño un truco, cabro: si no te gustan las cartas, las puedes cambiar. Te regalo un cambio más por partida. No me lo agradezcas. Págame."]],
	"despues_1-7": [["tuerca", "Toma, una bolsa de chatarra. La encontré en el auto de mi cuñado. Él ya no la va a usar."],
		["tuerca", "Mejora esos fierros, cabro. Lo que viene se comió dos camionetas."]],
	"antes_1-8": [["tuerca", "Llegó la hora. El Compactador. Se comió mi camioneta, mi otra camioneta y a mi cuñado, que no hizo tanta falta."],
		["calypso", "Cuando abre las mandíbulas se le ve el núcleo. Ahí recibe mucho más daño."]],
	"despues_1-8": [["tuerca", "¡LO HICISTE! ¡CAYÓ EL COMPACTADOR! ¡Mi camioneta está a salvo! Bueno, en pedazos, pero a salvo."],
		["tuerca", "Adentro venía esta nave vieja: la CAMPER. Lenta, pero pega de lejos. Como mi abogado."],
		["tuerca", "Ahora, antes de cada nivel, eliges con qué nave sales. Cada una trae su propia arma."],
		["calypso", "Detecto algo raro más allá del basural. Un mundo se acaba de apagar."],
		["tuerca", "Eh... seguro no es nada. ¿Quieres un sánguche?"],
		["tuerca", "Mientras tanto, te abrí la CHATARRERA INFINITA, al final del camino: enemigos sin parar hasta que revientes."],
		["tuerca", "Y si quieres, puedes partir de cero con todos tus fierros: NUEVA PARTIDA +, más duro y con mejor botín. O probar el modo EXTREMO. El portal lo arreglo pronto."]],
	"derrota": [["tuerca", "Te hicieron pebre, cabro. Pero volviste con fierros. Anda al Hangar, mejora la nave y dale de nuevo."]],
	"antes_1-R": [["tuerca", "¡Pasen, pasen! ¡La gran Ruleta de Don Tuerca! La armé con una lavadora y un semáforo."],
		["tuerca", "Gira dos veces. Puede salir plata, puede salir una horda, puede salir La Grúa. Tres iguales y salimos en las noticias."],
		["calypso", "He calculado tus probabilidades. Prefiero no decirlas."]],
	"despues_1-R": [["tuerca", "¡Ganaste! Mira lo que se quedó pegado en la ruleta: IMANCITO. Es un imán con patas. No sé. Te lo llevas."],
		["tuerca", "Vuelve cuando quieras: la casa siempre gana, pero a veces se distrae."]],
	"antes_1-INF": [["tuerca", "La Chatarrera Infinita. Aquí no se gana, cabro: se aguanta. Cada minuto llega más y más fuerte."],
		["tuerca", "Lo que aguantes se paga en chatarra y piezas. Y cada mundo que termines va a tener la suya."]],
	"nueva_plus": [["tuerca", "¿Otra vuelta? Eres de los míos. Te dejo todos tus fierros, pero a los robots les conté que venías."],
		["calypso", "Vienen más fuertes y sueltan mejores cosas. Yo voy a fingir que no sé cómo termina esto."]],
}


static func textos_calypso() -> Dictionary:
	return {
		"vida_baja": ["Vida baja. Ahora sería buen momento para ser bueno.", "Estamos en números rojos.", "Si mueres, yo me quedo con la nave."],
		"ace": ["ACE. Voy a guardar ese clip.", "Eso no era parte del plan. Me gusta."],
		"muerte": ["Skill issue.", "Lo guardo como aprendizaje."],
		"nam": ["Tu mascota se comió una bala. Otra vez.", "No sé qué le das de comer a esa cosa."],
		"afk": ["Detecto un AFK. Te mandaron un regalo.", "¿Sigues ahí? Ellos sí saben dónde estás.", "Quedarse quieto tiene consecuencias."],
	}

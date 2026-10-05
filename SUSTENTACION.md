# Guía de sustentación — Taller 2: PulsePass

Respuestas para explicar la capa de servicios con los conceptos y el alcance del PRD. En la sustentación conviene empezar por la responsabilidad de cada capa y luego justificar la decisión con un ejemplo del proyecto.

## 1. ¿Cuál es la responsabilidad de Service?

La capa Service implementa el comportamiento del negocio y coordina el caso de uso. Recibe la solicitud, consulta uno o varios repositories, valida las reglas, controla la transacción y transforma el resultado a un DTO mediante el mapper.

Por ejemplo, para comprar una entrada, `TicketService` busca al usuario y al evento, comprueba que estén habilitados para la compra, valida edad y capacidad, calcula el precio, guarda el ticket y cambia el evento a `SOLD_OUT` si se agotó el cupo. El Controller futuro podrá invocar el servicio sin conocer esos detalles.

## 2. ¿Qué diferencia existe entre Service y Repository?

El Repository se ocupa del acceso a los datos: buscar, contar y guardar entidades. El Service decide qué significa esa información para el negocio y orquesta la operación.

Por ejemplo, `TicketRepository` puede contar los tickets pagados de un evento. `TicketService` compara ese conteo con la capacidad del venue y decide si permite la compra. El Repository no debe decidir si una compra está permitida ni contener esa regla.

## 3. ¿Por qué Service no debería retornar entidades JPA?

Una entidad representa el modelo persistente y contiene asociaciones JPA; no necesariamente es el contrato apropiado para otras capas. Exponerla acopla el contrato público al esquema de persistencia, puede exponer datos que no se necesitan y puede causar problemas con asociaciones `LAZY` o ciclos entre entidades.

Por eso los servicios retornan DTOs, como `EventResponse` o `TicketResponse`. Por ejemplo, el ticket entrega `userEmail`, `eventCode` y `eventName`, en vez de exponer directamente `User` y `Event`.

## 4. ¿Qué ventaja tiene `record` para DTOs?

Un `record` permite declarar de forma concisa un objeto de transferencia con campos finales y métodos de acceso generados por Java. Evita escribir a mano constructor, getters, `equals`, `hashCode` y `toString`, y hace claro qué datos componen la solicitud o respuesta.

Por ejemplo, `PurchaseTicketRequest` solo contiene `userEmail`, `eventCode` y `type`. El precio no viene del cliente: se calcula en el servicio.

## 5. ¿Qué hace MapStruct?

MapStruct genera en compilación la implementación del mapeo entre objetos Java, por ejemplo de una entidad a un DTO. Así evitamos repetir conversiones manuales y detectamos problemas de mapeo durante la compilación.

En PulsePass, `TicketMapper` transforma `ticket.user.email` en `userEmail`, `ticket.event.eventCode` en `eventCode` y `ticket.event.name` en `eventName`. El servicio delega la transformación al mapper.

## 6. ¿Por qué preferir constructor injection?

La inyección por constructor deja explícitas las dependencias requeridas por la clase. Al declararlas `final`, no se pueden reemplazar accidentalmente después de construir el servicio; además, es sencillo suministrar mocks en una prueba unitaria.

Por eso las implementaciones reciben repositories y mappers en el constructor. Evitamos field injection con `@Autowired`, que oculta las dependencias y dificulta crear y probar el servicio de manera aislada.

## 7. ¿Qué diferencia existe entre `ResourceNotFoundException` y `BusinessRuleException`?

`ResourceNotFoundException` indica que el recurso solicitado no existe. Por ejemplo, no hay un evento con el código `CMF-2026`.

`BusinessRuleException` indica que el recurso sí existe, pero la operación no está permitida bajo las reglas del negocio. Por ejemplo, el evento existe, pero no está publicado, o el usuario no cumple la edad mínima.

El proyecto también usa `DuplicateResourceException` cuando existe un conflicto de unicidad, como intentar registrar un username que ya está ocupado.

## 8. ¿Por qué evitar `Optional.get()`?

`get()` falla con `NoSuchElementException` si el `Optional` está vacío, sin expresar qué recurso faltó ni ofrecer un mensaje útil para el dominio.

Es preferible encadenar `orElseThrow`, por ejemplo: `findByEventCode(code).orElseThrow(() -> new ResourceNotFoundException("Event not found: " + code))`. El error resultante es explícito y contextual.

## 9. ¿Cuándo utilizar `@Transactional(readOnly = true)`?

En las operaciones de lectura que no modifican datos, como buscar un venue, consultar un evento publicado o listar tickets. El proyecto establece `@Transactional(readOnly = true)` a nivel de servicio y declara `@Transactional` en cada operación de escritura.

`readOnly = true` expresa la intención de solo lectura y puede ayudar al manejo de la transacción y a optimizaciones del proveedor. No reemplaza las reglas de negocio ni debe tratarse como una garantía de seguridad para impedir cualquier escritura.

## 10. ¿Cuándo utilizar `@Transactional`?

En las operaciones que modifican datos, para que el conjunto de cambios se ejecute dentro de una transacción. En PulsePass, ejemplos son crear o publicar un evento, asociar un artista, registrar un usuario con su perfil, comprar o cancelar un ticket y marcarlo como usado.

La compra es un caso especialmente claro: guardar el ticket y actualizar el estado del evento cuando se llena la capacidad pertenecen a la misma transacción.

## 11. ¿Por qué una compra debe ser atómica?

Porque la compra es un solo caso de uso aunque tenga varios pasos: validar usuario y evento, revisar edad y cupo, calcular el precio, guardar el ticket y, si corresponde, cambiar el evento a `SOLD_OUT`. La atomicidad hace que todos esos cambios se confirmen juntos o que se reviertan si falla la operación.

Así evitamos completar solo una parte del proceso, por ejemplo actualizar el estado del evento sin registrar la entrada, o guardar la compra y dejar sin actualizar el estado que indica que se agotó la capacidad.

## 12. ¿Por qué la capacidad pertenece a una regla de Service?

El Repository proporciona los datos necesarios, por ejemplo, cuántos tickets pagados tiene un evento. La regla `paidTickets < venue.capacity` decide si todavía se puede comprar; esa decisión pertenece al negocio y, por tanto, al Service.

El Repository puede ofrecer la consulta de conteo, pero no debería decidir si la venta se permite ni qué excepción comunicar. El PRD aclara que el control de concurrencia entre compras simultáneas queda fuera del alcance académico; en producción habría que analizar mecanismos adicionales.

## 13. ¿Por qué el cálculo de edad pertenece al negocio?

La edad mínima es una condición del evento para permitir o rechazar la compra, no una responsabilidad de persistencia. El Service compara la fecha de nacimiento del perfil con la fecha del evento, porque la regla pide evaluar la edad que tendrá la persona ese día, no necesariamente su edad de hoy.

Si no alcanza la edad mínima, el servicio rechaza la compra con `BusinessRuleException` antes de guardar el ticket.

## 14. ¿Por qué utilizar `BigDecimal` para precios?

Porque los precios son cantidades decimales de dinero. Los tipos binarios de punto flotante, como `float` y `double`, pueden representar algunos decimales con pequeñas imprecisiones; eso no es deseable en cálculos monetarios.

`BigDecimal` representa el precio decimal de forma apropiada y permite definir precios como `new BigDecimal("50.00")`. En el proyecto, el servicio mantiene la estrategia de precios para GENERAL, STUDENT, VIP y BACKSTAGE, en vez de confiar el precio al cliente.

## 15. ¿Qué diferencia existe entre unit test e integration test?

Un test unitario comprueba una unidad de comportamiento aislada. Para la capa Service se ejecuta el servicio real y se sustituyen sus collaborators, como repositories y mapper, por mocks de Mockito; no hace falta iniciar Spring ni conectarse a PostgreSQL.

Un test de integración comprueba que varias partes reales colaboren, por ejemplo Spring Data JPA, Hibernate, Flyway y PostgreSQL. El laboratorio de persistencia usa Testcontainers para esa clase de verificación. Los tests de esta capa de servicios son unitarios, como especifica el PRD.

## 16. ¿Por qué Mockito permite probar Service sin PostgreSQL?

Mockito reemplaza los repositories y mappers reales por objetos controlados por la prueba. Con `when(...)` podemos definir qué devolverá una búsqueda y con `verify(...)` comprobar qué colaboración ocurrió.

Así podemos centrarnos en la regla del Service —por ejemplo, que un usuario inactivo no genere un ticket— sin ejecutar SQL, iniciar Hibernate ni levantar una base de datos. Los tests verifican la lógica del servicio, no la integración con PostgreSQL.

## 17. ¿Qué demuestra `verify(repository, never()).save(...)`?

Demuestra que el servicio no intentó guardar la entidad en ese escenario. Se usa después de comprobar un error de negocio para probar que el flujo inválido se detuvo antes de persistir.

Por ejemplo, si el usuario está inactivo o el evento ya no tiene capacidad, esperamos una excepción y verificamos que `ticketRepository.save(...)` nunca se llamó. Esto comprueba tanto el resultado como la ausencia del efecto secundario indebido.

## 18. ¿Por qué `SOLD_OUT` debe actualizarse dentro de la misma transacción?

Porque el ticket y el estado del evento son dos cambios del mismo proceso de compra. Si el ticket es el último disponible, ambos deben confirmarse juntos: el ticket queda registrado y el evento pasa a `SOLD_OUT`.

Al ejecutar esos cambios en la misma transacción, un fallo revierte el conjunto en vez de dejar un resultado parcial. Esa es la atomicidad solicitada por el PRD.

## 19. ¿Por qué Ticket es una entidad y no solo una relación N:M?

Un ticket no representa únicamente el vínculo entre un usuario y un evento. Tiene datos y ciclo de vida propios: código, tipo, precio, fecha de compra y estado (`PAID`, `USED` o `CANCELLED`). Además, las operaciones de compra, cancelación y uso cambian su estado.

Una tabla de unión simple no expresaría por sí sola todo ese comportamiento. Por eso `Ticket` es una entidad propia relacionada con `User` y `Event`: un usuario puede tener muchos tickets y un evento puede tener muchos tickets.

## 20. ¿Qué reglas moverías a componentes especializados si PulsePass creciera?

Primero observaría si una responsabilidad ganó suficiente complejidad para tener su propio componente. El PRD menciona como posibles evoluciones `PricingService`, `CapacityService`, `PaymentService`, `RecommendationService` y `NotificationService`.

Por ejemplo, si la estrategia de precios incorporara promociones y descuentos, podría extraerse a `PricingService`; si la gestión de cupos incluyera concurrencia o reservas, podría evolucionar hacia `CapacityService`. El Service del caso de uso seguiría coordinando la operación. No agregaría esos componentes antes de necesitarlos: no forman parte de la entrega actual.

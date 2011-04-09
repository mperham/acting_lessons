Scalable Processing with Rubinius and Actors
===================================================

Actors are a system borrowed from Erlang which try to make concurrent processing simpler than standard Thread-based systems.  Instead using locks and shared data structures, actors pass messages to each other so there is no shared state.  Since Rubinius is going to be removing the main barrier to scalability (the GIL) very soon, Rubinius + actors have the potential to unlock easy and scalable concurrency which has been missing from Ruby until now.

I've created a WorkQueue abstraction on top of the Actor API which handles the common chores.  A good example is worth a 100 pages of API documentation.  See application.rb and work_queue.rb for details.

TODO:

 - Write up explanation and integrate into Rubinius's documentation.


Thanks
---------------

Carbon Five - for giving me free time to work on this project <http://carbonfive.com>.

MenTaLguY - for explaining how actors work and fixing a Rubinius bug that prevented exit notification from working.
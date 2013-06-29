DownloadOrganizer
=================

The intention is to create a complete solution to automated identification of downloaded movies and tv shows including moving and organizing the files into the correct directories on your disk. This app is also capable of unraring the rar files you download. The goal is to have a complete web ui for showing the automated results and to modify misidentifications if necessary. You put this web app on the server you use for downloading files and then you can go to this app when you want to move all your new downloads to their correct locations.

To run this app first make sure you have rails and rubys setup on your server. Find a guide to setting up rails on your servers environment.

Then clone the repository:
    
    cd /where/you/want/to/put/the/app
    git clone https://github.com/DylanGriffith/DownloadOrganizer.git
    cd DownloadOrganizer
    
Install gems:

    gem install bundler
    bundle install
    
Setup database stuff. Although, currently, the database is not used by this app you will still need to have some database setup on your server and you will need to add a configuration file for that connection. Included is an example database.yml for mysql and you will need to add passwords for your mysql server. Otherwise change it to a different database type if you prefer.

    cp config/database.example.yml config/database.yml
    vim config/database.yml

After you have setup database settings create the databases and run the tests to confirm everything is okay:

    bundle exec rake db:create
    bundle exec rake db:migrate
    bundle exec rake test
    
Now setup your environment the way you want it. You will need to edit the settings file to reflect where new downloads are stored, where you store your movies and where you store your tv shows. Lastly you will need to set the username and password you want to have for accessing the web page.

    cp config/settings.example.json config/settings.json
    vim config/settings.json
   
Now run the app:

    RAILS_ENV=production bundle exec rails s

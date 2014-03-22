var mongo = require('mongodb');
var fs = require('fs');
var restler = require('restler');
var formidable = require ('formidable');
var path = require ('path');
var util = require ('util');


var BSON = mongo.BSONPure;

/* We use this to test Mongo ID's */
var checkForHexRegExp = new RegExp("^[0-9a-fA-F]{24}$")

/*
 * GET Job
 */

 exports.getJob = function(db) {

    return function(req, res){
        /* Set our collection */
        var groups_col= db.collection('groups');
        var group_id = req.params.group_id;
	
        console.log('GET request parameters are: ' + util.inspect(req.params) );
	
        if(req.params.group_id){
            console.log('Retrieving job: ' + group_id);
            /* Check if valid GroupID */
            if(checkForHexRegExp.test(group_id)){
                try{
                    groups_col.findOne({'_id':new BSON.ObjectID(group_id)}, function(err, item) {
                        if(item === null){
                            res.send('There is no document in the collection matching that GroupID!');
                        }
                        else {
                            res.send(item);
                        }
                    });
                }
                catch(err){
                    console.log(err);
                    res.send("Error retrieving the GroupID: " + group_id);
                }
            }
            else{
                res.send("You did not submit a valid GroupID!");
            }
        }    
        else{
            res.send("You did not submit a GroupID");
        }
    };
};

/*
 * POST Image
 */
exports.upload = function(db, configArgs) {
    
    return function(req, res) {

        /* Store graphicServer details */
        var graphicServer = "http://" + configArgs.classifier_host + ":" + configArgs.classifier_port;
        /* Make formidable the multipart form parser */
        var form = new formidable.IncomingForm();

        /* Switch our uploadDIR depending on how this is being run. */
        /* istanbul ignore else */
        /* Ignored by Istanbul because this ONLY goes one way during TEST and PROD respectively */
        if(process.env.NODE_ENV ==='test'){
            form.uploadDir = path.join('./lib/AppServer/uploads', configArgs.db_database);
        }
        else{
            form.uploadDir = path.join('./Nodejs/lib/AppServer/uploads', configArgs.db_database);
        }

        form.keepExtensions = true;	

        /* preset wait time at the moment */
        var waitTime = 2;
		
        /* log the body of this upload */
        form.parse(req, function (err, fields, files) {

            //console.log('POST request body is: \n' + util.inspect({fields: fields, files: files}) );    

            try {
                filePath = files.datafile.path;
            }
            catch(err){
                res.send('Nothing to add to database: there is no Datafile attached!');
                return err;
            }

            if (!fields.segment){
                res.send('You did not supply a segment type, I cannot continue');
                return -1;
            }

            /* output where we saved the file */
            //console.log("FilePath is: \n" + filePath);

            /* Set our collections */
            try{
                var segment_images_col = db.collection('segment_images');
                var groups_col = db.collection('groups');
            }
            catch(err){
                res.send("Error connecting to the Database collections!");
                console.log(err);
                return err;
            }

            /* We may need to create the group document and get its ID back */
            var group_id = -1;

            segment_document = {
                vm_filepath : filePath,
                group_id : group_id,
                submission_state : "File Submitted from App",
                submission_time : Math.round(new Date().getTime() / 1000),
                image_metadata : {
                    date : fields.date,
                    latitude : fields.latitude,
                    longitude : fields.longitude
                },
                image_segment : fields.segment 
            }

            if (fields.group_id === '0'){
                groups_col.insert(
                    {
                        group_status: "uploading",
                        image_count : 1,
                        classified_count: 0
                    },
                    {safe: true}, 
                    function (db_err, g_docs) {
                        if (db_err) {
                            /* If it failed, return error */
                            res.send("There was a problem adding the information to the GROUPS collection");
                            return db_err;
                        }
                        else {
                            /* Get the id of the group document */
                            group_id = g_docs[0]._id;
                            segment_document.group_id = group_id;
                            
                            /* Submit to the DB */
                            segment_images_col.insert(
                                segment_document,
                                {safe: true}, 
                                function (db_err, docs) {
                                    if (db_err) {
                                        /* If it failed, return error */
                                        res.send("There was a problem adding the information to the SEGMENT_IMAGES collection");
                                        return db_err;
                                    }
                                    else {
                                        /* If it worked, return JSON object from collection to App */
                                        res.json( { id : docs[0]._id, group_id : docs[0].group_id });
                                        //console.log({ id : docs[0]._id, group_id : docs[0].group_id });
                                        /* Send the image over to the classifier */
                                        restler.post(graphicServer + "/classify", {
                                            multipart: true,
                                            data: {
                                                segment_id: docs[0]._id,
                                                group_id: docs[0].group_id,
                                                image_segment: docs[0].image_segment,
                                                datafile: restler.file(files.datafile.path, null, files.datafile.size, null, "image/jpeg")
                                            }
                                        }).on("complete", function(data) {
                                            //console.log("GraphicServer response: \n" + util.inspect(data) );
                                        });
                                    }
                            });
                        }
                    }); 
            }
            else {
                if(checkForHexRegExp.test(fields.group_id)){
                    try{
                        /* Turn groupID into ObjectID */
                        group_id = new BSON.ObjectID(fields.group_id);
                        /* Store objectID in doc to be inserted */
                        segment_document.group_id = group_id;

                        /* Increment the number of images in group */
                        groups_col.update(
                            {_id : group_id },
                            { $inc: { image_count: 1 } },
                            {safe:true},
                            function (db_err, docs) {
                                if (db_err) {
                                    /* If it failed, return error */
                                    res.send("There was a problem incrementing the image_count in GROUP collection");
                                    return -1;
                                }
                            }
                            );

                        /* Submit to the SegmentDB */
                        segment_images_col.insert(
                            segment_document,
                            {safe: true}, 
                            function (db_err, docs) {
                                if (db_err) {
                                    /* If it failed, return error */
                                    res.send("There was a problem adding the information to the SEGMENT_IMAGES collection");
                                    return -1;
                                }
                                else {
                                    /* If it worked, return JSON object from collection to App */
                                    res.json( { id : docs[0]._id, group_id : docs[0].group_id });
                                    //console.log({ id : docs[0]._id, group_id : docs[0].group_id });
                                    /* Send the image over to the classifier */
                                    restler.post(graphicServer + "/classify", {
                                        multipart: true,
                                        data: {
                                            segment_id: docs[0]._id,
                                            group_id: docs[0].group_id,
                                            image_segment: docs[0].image_segment,
                                            datafile: restler.file(files.datafile.path, null, files.datafile.size, null, "image/jpeg")
                                        }
                                    }).on("complete", function(data) {
                                        //console.log("GraphicServer response: \n" + util.inspect(data) );
                                    });
                                }
                            });
                    }
                    catch(err){
                        res.send("Error whilst updating group!");
                        console.log("Error whilst updating group with image: " + err);
                        return -1;
                    }
                }
                else{
                    res.send("You did not submit a valid GroupID!");
                }
            }


		
        })
    };
};


/*
 * Put Completion
 */

 exports.putComplete = function(db) {

    return function(req, res){
        /* Set our collection */
        var groups_col= db.collection('groups');
        var group_id = req.params.group_id;
    
        // console.log('PUT request parameters are: ' + util.inspect(req.params) );

        /* Make formidable the multipart form parser */
        var form = new formidable.IncomingForm();
    
        form.parse(req, function (err, fields, files) {

            /* Extract status from put request */
            var new_status = (fields.completion === "true") ? "Complete" : "Cancelled";

            if(req.params.group_id){
                console.log('Finding job: ' + group_id);
                try{
                    groups_col.findAndModify(
                        { _id : new BSON.ObjectID(group_id) },
                        {}, //sort order
                        { $set: {group_status: new_status } }, //replace status
                        {new: false}, //give us the  old record
                        function (db_err, docs) {
                            if (db_err) {
                                /* If it failed, return error */
                                res.send("Could not find that GroupID in the DB");
                                return db_err;

                            }
                            else{
                                /* If it worked, return JSON object from collection to App */
                                var has_updated = (docs.group_status !== new_status) ? "true" : "false";
                                res.json( { group_id : docs._id, completion_status : fields.completion, updated: has_updated });
                                //console.log({ group_id : docs._id, completion_status : fields.completion, updated: has_updated }) ;

                            }
                        });
                }
                catch(err){
                    console.log(err);
                    res.send("You did not submit a valid GroupID!");
                }
            }
            else{
                res.send("You did not submit a GroupID");
            }

        });

    };
};

function objectIdWithTimestamp(secondsAgo)
{
    // Convert string date to Date object (otherwise assume timestamp is a date)
    timestamp = new Date();

    // Convert date object to hex seconds since Unix epoch
    var hexSeconds = Math.floor((timestamp/1000)-secondsAgo).toString(16);

    // Create an ObjectId with that hex timestamp
    var constructedObjectId = BSON.ObjectID(hexSeconds + "0000000000000000");

    return constructedObjectId
}

exports.forceOld = function(db) {

    return function(req, res) {

        var groups_col= db.collection('groups');
        var segment_col = db.collection('segment_images');
        var groupsUpdated = [];

        /* Get the time five minutes ago */
        var fiveMinutesAgo = objectIdWithTimestamp(300);


        try{
            /* reset documents with no classification created > 5 minutes ago */
            groups_col.find({'classification': {'$exists' : false}, '_id' : {$lt : fiveMinutesAgo} }, 
                {'fields': {'_id':1,'group_status':2}}).toArray(
                function(err, docs) {
                    /* for each result, set count to zero and reset segments */
                    for (var i=0;i < docs.length; i++){
                        
                        /* Only update the groups for those that are complete */
                        groups_col.update({'_id' : docs[i]._id}, {$set : {'classified_count' :0}}, {'w':1}, function(err, numberUpdated) {
                            if(err){
                                console.log("Error updating classification count on " + docs[i]._id);
                                throw err;
                            }
                            else{
                            }
                        });

                        /* put the updated group on the array */
                        groupsUpdated.push(docs[i]._id + " : " + docs[i].group_status)

                        segment_col.update({'group_id' : docs[i]._id}, {$set : {'submission_state' : 'File received by graphic'}}, {'w' : 1, 'multi' : true}, function(err, numberUpdated){
                            if(err){
                                console.log("Error updating submission state on document.");
                                throw err;
                            }
                        });
                    }
                    /* send response */
                    res.json(groupsUpdated);

                });
        }
        catch(err){
            console.log(err);
            res.send("Error " + err);
        }

    }
}
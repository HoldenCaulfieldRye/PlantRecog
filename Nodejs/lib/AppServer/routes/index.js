var mongo = require('mongodb');
var fs = require('fs');
var restler = require('restler');
var formidable = require ('formidable');
var path = require ('path');
var util = require ('util');


var BSON = mongo.BSONPure;

/*
 * GET Job
 */
function insert_segment(collection, segment_document){


};

 exports.getJob = function(db) {

    return function(req, res){
        /* Set our collection */
        var groups_col= db.collection('groups');
        var group_id = req.params.group_id;
	
        console.log('GET request parameters are: ' + util.inspect(req.params) );
	
        if(req.params.job_id){
            console.log('Retrieving job: ' + group_id);
            try{
                groups_col.findOne({'_id':new BSON.ObjectID(group_id)}, function(err, item) {
                    if(item === null){
                        res.send('There is no document in the collection matching that JobID!');
                    }
                    else {
                        res.send(item);
                    }
                });
            }
            catch(err){
                console.log(err);
                res.send("You did not submit a valid JobID!");
            }
        }
        else{
            res.send("You did not submit a JobID");
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

            console.log('POST request body is: \n' + util.inspect({fields: fields, files: files}) );    

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
            console.log("FilePath is: \n" + filePath);

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
                                        console.log({ id : docs[0]._id, group_id : docs[0].group_id });
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
                                            console.log("GraphicServer response: \n" + util.inspect(data) );
                                        });
                                    }
                            });
                        }
                    }); 
            }
            else {
                group_id = fields.group_id;
                segment_document.group_id = group_id;

                /* Increment the number of images in group */
                groups_col.update(
                    {_id : new BSON.ObjectID(group_id) },
                    { $inc: { image_count: 1 } },
                    {safe:true},
                    function (db_err, docs) {
                        if (db_err) {
                            /* If it failed, return error */
                            res.send("There was a problem incrementing the image_count in GROUP collection");
                            return db_err;
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
                            return db_err;
                        }
                        else {
                            /* If it worked, return JSON object from collection to App */
                            res.json( { id : docs[0]._id, group_id : docs[0].group_id });
                            console.log({ id : docs[0]._id, group_id : docs[0].group_id });
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
                                console.log("GraphicServer response: \n" + util.inspect(data) );
                            });
                        }
                });
            }


		
        })
    };
};



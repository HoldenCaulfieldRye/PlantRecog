//-----------------------------------------
//------------BUCKETING ALGO---------------
//-----------------------------------------

var count_by_synset = new Object();

function bucketing(threshold, tag, prob){
	print("Bucketing with the following params: "+threshold+":"+tag+":"+prob);
	
	//reset count to zero!!!
	print("Resetting collection for new bucketing session...");
	db.plants.update({}, {$set:{Count:0, BucketCount:0, Bucket:"", BucketSpecies:""}}, {multi : true});
	var counts = db.plants.distinct('Count');
	if(counts.length>1 || counts[0]!=0){
		print("ERROR: Doesn't look like all documents were reset");
		return 2;
	}	

	print("Initialing aggregated count of synsets: " + new Date().timeNow());
	initialise_count_agg(tag,prob);
	
	//find leaf nodes (easiest to find)
	print("Updating count of all nodes: " + new Date().timeNow());
	var cursor = db.taxonomy.find({Children : [ ] }, {Parent:1, Path:1, _id:0});
	//for each leaf node traverse its path updating the count of elements below it
	for (var i =0; i< cursor.length();i++){
		var parent = eval(tojson(cursor[i]["Parent"]));
		var path = eval(tojson(cursor[i]["Path"]));
		path.unshift(parent);
		traverse_update_descendant_count(path);			
	}
	
	print("Updating buckets: " + new Date().timeNow());
	var cursor = db.taxonomy.find({Children : [ ] }, {Parent:1, Path:1, _id:0});
	for (var i =0; i< cursor.length();i++){
		var parent = eval(tojson(cursor[i]["Parent"]));
		var path = eval(tojson(cursor[i]["Path"]));
		path.unshift(parent);
		traverse_update_bucket(path, threshold);			
	}
/*
	print("Finalising bucket count: " + new Date().timeNow());
	finalise_bucket_count(tag,prob);
*/
	print("Bucketing finished: " + new Date().timeNow());
}

function initialise_count_agg(tag, prob){
	var running_count = 0;
	if(tag){
		print("...Aggregating by tag and prob: " + tag, ", " + prob);
	    var res = db.plants.aggregate(
			{ $match : {Component_Tag : tag , Component_Tag_Prob : { $gte : prob } , Exclude : false }}, 
			{ $group : { _id : "$Synset_ID", count : { $sum : 1 } }}
		);
	}
	else{
		print("...No tag provided, aggregating by prob only");
	    var res = db.plants.aggregate(
			{ $match : {Component_Tag_Prob : { $gte : prob } , Exclude : false }}, 
			{ $group : { _id : "$Synset_ID", count : { $sum : 1 } }}
		);
	}
	for (var i = 0 ; i< res.result.length; i++ ){
		running_count+=res.result[i].count;
		count_by_synset[res.result[i]._id] = res.result[i].count;
	}
	count_by_synset["n00017222"] = running_count;
}

var missing_synsets = [];

function traverse_update_descendant_count(path){
	var count = 0;
	//var spec = "plant, flora, plant life";
	if(!path.length) { print("WARN: path with no length");}
	for (var i in path){
		var node = path[i];
		//count+=(count_by_synset[node] || 0);
		count+=(count_by_synset[node] || 0);
		var data = (db.plants.findOne({Synset_ID : node}, {Species:1,Count:1, _id:0}));
		if(data){
			//spec = data.Species;
			//db.plants.update({Synset_ID : node, Exclude : false}, {$inc : {Count : count}, $set : {Bucket : node}}, {multi : true});
			//db.plants.update({Synset_ID : node, Exclude : true }, {$inc : {Count : 0    }, $set : {Bucket : node}}, {multi : true});
			//db.plants.update({Synset_ID : node, Exclude : false}, {$inc : {Count : count}, $set : {Bucket : node}, $set : {BucketSpecies: spec}}, {multi : true});
			//db.plants.update({Synset_ID : node, Exclude : true }, {$inc : {Count : 0    }, $set : {Bucket : node}, $set : {BucketSpecies: spec}}, {multi : true});
			//db.plants.update({Synset_ID : node}, {$inc : {Count : count}, $set: {Bucket:node, BucketSpecies:data.Species}}, {multi : true});
			db.plants.update({Synset_ID : node}, {$set: {Bucket:node, BucketSpecies:data.Species}, $inc : {Count:count}}, {multi : true});
			//db.plants.update({Synset_ID : node}, {$set: {Bucket:node, BucketSpecies:data.Species, Count:count}}, {multi : true});
		}
		else{
			//print("Synset_ID: " + node + " NOT in database");
			missing_synsets.push(node);
		}
	}
}

//db.plants.findOne({Synset_ID : "n12271643"}).Count - (db.taxonomy.findOne({Parent : "n12271643"}).Children.length * db.plants.findOne({Synset_ID : "n12271643"}).Count)


function traverse_update_bucket(path, threshold){
	//var running_count = 0;
	var count = 0;
	var index = 0;
	var bucket;
	for (var i=0; i<path.length; i++){
		bucket = path[i];
		var data = db.plants.findOne({Synset_ID : bucket}, {Count:1 , _id:0});
		if(data) count=(data.Count || 0);
		if(count >= threshold){
			index = i;
			break;
		}
	}
	if(index>0){
		var spec = (db.plants.findOne({Synset_ID : bucket}, {Species:1, _id:0})).Species;
		//db.plants.update({ Synset_ID: {$in: path.slice(0,index)} , Exclude : false} , {$set : { Bucket : bucket }} , {multi : true});
		//db.plants.update({ Synset_ID: {$in: path.slice(0,index)} , Exclude : false} , {$set : { Bucket : bucket }, $set : {BucketSpecies: spec}} , {multi : true});
		db.plants.update({ Synset_ID: {$in: path.slice(0,index)}} , {$set: {Bucket:bucket, BucketSpecies:spec}} , {multi : true});
	}
}


function finalise_bucket_count(tag, prob){
	if(tag){
	    var res = db.plants.aggregate(
			{ $match : {Component_Tag : tag , Component_Tag_Prob : { $gte : prob } , Exclude : false }}, 
			{ $group : { _id : "$Bucket", count : { $sum : 1 } }}
		);
	}
	else{
	    var res = db.plants.aggregate(
			{ $match : {Component_Tag_Prob : { $gte : prob } , Exclude : false }}, 
			{ $group : { _id : "$Bucket", count : { $sum : 1 } }}
		);
	}
	for (var i = 0 ; i< res.result.length; i++ ){
		db.plants.update({Bucket:res.result[i]._id}, {$set : {BucketCount : res.result[i].count}}, {multi:true});
	}
}




Date.prototype.timeNow = function () { 
	return ((this.getHours() < 10) ? "0" : "") +
		     this.getHours() + ":" +
		   ((this.getMinutes() < 10) ? "0" : "") +
             this.getMinutes() +":" +
           ((this.getSeconds() < 10) ? "0" : "") +
             this.getSeconds();
}

var TAG = TAG || null;
var PROB = parseFloat(PROB) || 0.0;
bucketing(THRES, TAG, PROB);

/*
var flags = [], output = [], l = missing_synsets.length, i;
for( i=0; i<l; i++) {
    if( flags[missing_synsets[i]]) continue;
    flags[missing_synsets[i]] = true;
    output.push(missing_synsets[i]);
}
print("Missing Synsets Identified: " + output);
*/




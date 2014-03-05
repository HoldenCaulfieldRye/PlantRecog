//-----------------------------------------
//------------BUCKETING ALGO---------------
//-----------------------------------------

var count_by_synset = new Object();

function bucketing(threshold, tag, prob){
	print("Bucketing with the following params: "+threshold+":"+tag+":"+prob);
	print("Resetting collection for new bucketing session...");
	db.plants.update({}, {$set:{Count:0, BucketCount:0, Bucket:"", BucketSpecies:""}}, {multi : true});
	var counts = db.plants.distinct('Count');
	if(counts.length > 1 || counts[0] != 0){
		print("ERROR: Doesn't look like all documents were reset");
		return 2;
	}	

	print("Initialing aggregated count of synsets: " + new Date().timeNow());
	initialise_count_agg(tag,prob);
	
	print("Updating count of all nodes: " + new Date().timeNow());
	//for each leaf node traverse its path updating the count of all elements below it
	db.taxonomy.find({Children : [ ] }, {Parent:1, Path:1, _id:0}).forEach(function(data){
		var path = data.Path;
		path.unshift(data.Parent);
		traverse_update_descendant_count(path);			
	});
	
	print("Updating buckets: " + new Date().timeNow());
	var cursor = db.taxonomy.find({Children : [ ] }, {Parent:1, Path:1, _id:0});
	for (var i=0; i<cursor.length(); i++){
		var parent = eval(tojson(cursor[i]["Parent"]));
		var path = eval(tojson(cursor[i]["Path"]));
		path.unshift(parent);
		traverse_update_bucket(path, threshold);			
	}
	print("Bucketing finished: " + new Date().timeNow());
}

function initialise_count_agg(tag, prob){
	var running_count = 0;
	var res;
	if(tag){
		print("...Aggregating by tag and prob: " + tag, ", " + prob);
	    res = db.plants.aggregate(
			{ $match : {Component_Tag : tag , Component_Tag_Prob : { $gte : prob } , Exclude : false }}, 
			{ $group : { _id : "$Synset_ID", count : { $sum : 1 } }}
		);
	}
	else{
		print("...No tag provided, aggregating by prob only");
	    res = db.plants.aggregate(
			{ $match : {Component_Tag_Prob : { $gte : prob } , Exclude : false }}, 
			{ $group : { _id : "$Synset_ID", count : { $sum : 1 } }}
		);
	}
	for (var i = 0 ; i< res.result.length; i++){
		running_count+=res.result[i].count;
		count_by_synset[res.result[i]._id] = res.result[i].count;
	}
	//update the root to be the sum of all other 
	count_by_synset["n00017222"] = running_count;
	return 1;
}


function traverse_update_descendant_count(path){
	var count = 0;
	if(!path.length) return -1;
	for (var i in path){
		var node = path[i];
		count+=(count_by_synset[node] || 0);
		var data = (db.plants.findOne({Synset_ID : node}, {Species:1,Count:1, _id:0}));
		if(data){
			db.plants.update({Synset_ID : node}, {$set: {Bucket:node, BucketSpecies:data.Species}, $inc : {Count:count}}, {multi : true});
		}
	}
	return 1;
}

function traverse_update_bucket(path, threshold){
	var count = 0;
	var index = 0;
	var bucket;
	if(!path.length) return -1;
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
		db.plants.update({ Synset_ID: {$in: path.slice(0,index)}} , {$set: {Bucket:bucket, BucketSpecies:spec}} , {multi : true});
	}
	return 1;
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
//bucketing(THRES, TAG, PROB);





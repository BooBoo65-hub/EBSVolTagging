
# Author: Zain Saleh
# Date: 13-05-2020
# Description: Script to evaluate EBS Volume Tags. Looks through all instances in account based on KEy Tag variables and for each volume on each instance the Attachment Tag is added to each volume associated to that instance

## Usage Notes: 
### environment variables:
#### dryrun -- Allows the script to run in test mode and without actually doing any changes. Set to yes for Dryrun or no to run the script in a non test mode, selecting no script will run in full install mode.
#### tag_key -- This is used as the Key Tag criteria to select instances. This can be changed and can be any Key Tag value you wish to search for.
#### tag_value -- This is the value in the Key you are searching for, in this instance * selects any value. You can be more granular if needed and look for a specific Key value, ie value=OS etc.
#### ec2array -- This is the array that holds InstanceID,s for the instances found from AWS describe instances request.
#### tagarray -- This is the array that holds all of the Key Tags associated to the volumeID and InstanceID for use in Case statement.
#### volarray -- This is the array that holds all the VolumeID,s for each instance
#### dAttachment -- Query Volumes for value of device block-attachment for each volumeID
#### tagarray1 -- This is the array that holds all of the Key Tags associated to the volumeID for use in Case statement

### case variables:
### Temporary variables used in case statements to assign tag values to variable for Instance Tags and Volume Tags for if and else evaluation statements.
#### itmpname -- Holds the Tag Key value for NAME from InstanceID
#### itmpenv -- Holds the Tag Key value for ENVIRONMENT from InstanceID
#### itmpos -- Holds the Tag Key value for OS from InstanceID
#### itmpown -- Holds the Tag Key value for OWNER from InstanceID
#### itmpproj -- Holds the Tag Key value for PROJECT from InstanceID
#### itmprel -- Holds the Tag Key value for RELEASE from InstanceID
#### itmprol -- Holds the Tag Key value for ROLE from InstanceID
#### itmpatt -- Holds the Tag Key value for ATTACHMENT from InstanceID
#### vtmpname -- Holds the Tag Key value for NAME from VolumeID
#### vtmpenv -- Holds the Tag Key value for ENVIRONMENT from VolumeID
#### vtmpos -- Holds the Tag Key value for OS from VolumeID
#### vtmpown -- Holds the Tag Key value for OWNER from VolumeID
#### vtmpproj -- Holds the Tag Key value for PROJECT from VolumeID
#### vtmprel -- Holds the Tag Key value for RELEASE from VolumeID
#### vtmprol -- Holds the Tag Key value for ROLE from VolumeID
#### vtmpatt -- Holds the Tag Key value for ATTACHMENT from VolumeID


# dryrun yes or no - uses aws cli dry-run parameter to check and not perform processing
dryrun="no"

tag_key="Name"
tag_value="*"

# Queries Instances based on Tag Key and value and stores in ec2rray

ec2array=(`aws ec2 describe-instances --filter "Name=tag:$tag_key,Values=$tag_value" --query "Reservations[*].Instances[*].[InstanceId]" --output text`)


# Loops through ec2array and stores query results in to tagarray. Case statement is used to assign the correct values to variables for evaluation in if and else statements.

for instance in "${ec2array[@]}"
do
 #       echo $instance
        processing_instance=$instance
        tagarray=(`aws ec2 describe-instances --instance-id $instance --query "Reservations[*].Instances[*].[[Tags[?Key=='Name'].Value][0],[Tags[?Key=='Environment'].Value][0],[Tags[?Key=='OS'].Value][0],[Tags[?Key=='Owner'].Value][0],[Tags[?Key=='Project'].Value][0],[Tags[?Key=='Release'].Value][0],[Tags[?Key=='Role'].Value][0],[Tags[?Key=='Attachment'].Value][0]]" --output text`)
        #echo "tagarray has "${#tagarray[@]}" items"
        tagmax=${#tagarray[@]}
        tag_count=1
        for tags in "${tagarray[@]}"
                do
                        #echo $tags
                        case    "$tag_count" in
                        1)
                        itmpname=$tags
                        ;;
                        2)
                        itmpenv=$tags
                        ;;
                        3)
                        itmpos=$tags
                        ;;
                        4)
                        itmpown=$tags
                        ;;
                        5)
                        itmpproj=$tags
                        ;;
                        6)
                        itmprel=$tags
                        ;;
                        7)
                        itmprol=$tags
                        ;;
                        8)
                        itmpatt=$tags
                        ;;
                        esac
                tag_count=$(($tag_count+1))
                done


# Queries Volumes based on $instance and stores in volarry

volarray=(`aws ec2 describe-volumes --filters Name=attachment.instance-id,Values=$instance --query 'Volumes[*].{ID:VolumeId}' --output text`)

# Loops through volarray and stores query results in to tagarray1. Case statement is used to assign the correct values to variables for evaluation in if and else statements

for volume in "${volarray[@]}"
do
        dAttachment=$(aws ec2 describe-volumes --volume-ids $volume --query "Volumes[*].Attachments[*].[Device]" --output text)

        processing_volume=$volume
        tagarray1=(`aws ec2 describe-volumes --volume-id $volume --query "Volumes[*].[[Tags[?Key=='Name'].Value][],[Tags[?Key=='Environment'].Value][],[Tags[?Key=='OS'].Value][],[Tags[?Key=='Owner'].Value][],[Tags[?Key=='Project'].Value][],[Tags[?Key=='Release'].Value][],[Tags[?Key=='Role'].Value][],[Tags[?Key=='Attachment'].Value][]]" --output text`)

        tagmax=${#tagarray1[@]}
        tag_count=1
        for tags in "${tagarray1[@]}"
                do
                        #echo $tags
                        case    "$tag_count" in
                        1)
                        vtmpname=$tags
                        ;;
                        2)
                        vtmpenv=$tags
                        ;;
                        3)
                        vtmpos=$tags
                        ;;
                        4)
                        vtmpown=$tags
                        ;;
                        5)
                        vtmpproj=$tags
                        ;;
                        6)
                        vtmprel=$tags
                        ;;
                        7)
                        vtmprol=$tags
                        ;;
                        8)
                        vtmpatt=$tags
                        ;;
                        esac
                tag_count=$(($tag_count+1))
                done

# Evaluation of Instance Tag NAME v Volume Tag NAME
                                    if [ $dryrun = "yes" ]; then
                                       [ "$itmpname" != "None" ] && [ "$vtmpname" == "None" ]
                                        aws ec2 create-tags --dry-run --resources $volume --tags Key=Name,Value="'`echo $itmpname`'"
                                    else
                                       [ "$itmpname" != "None" ] && [ "$vtmpname" == "None" ]
                                        aws ec2 create-tags --resources $volume --tags Key=Name,Value="'`echo $itmpname`'"
                                    fi

# Evaluation of Instance Tag ENVIRONMENT v Volume Tag ENVIRONMENT
                                    if [ $dryrun = "yes" ]; then
                                       [ "$itmpenv" != "None" ] && [ "$vtmpenv" == "None" ]
                                        aws ec2 create-tags --dry-run --resources $volume --tags Key=Environment,Value="'`echo $itmpenv`'"
                                    else
                                       [ "$itmpenv" != "None" ] && [ "$vtmpenv" == "None" ]
                                        aws ec2 create-tags --resources $volume --tags Key=Environment,Value=`echo $itmpenv`
                                    fi

# Evaluation of Instance Tag OS v Volume Tag OS
                                    if [ $dryrun = "yes" ]; then
                                       [ "$itmpos" != "None" ] && [ "$vtmpos" == "None" ]
                                        aws ec2 create-tags --dry-run --resources $volume --tags Key=OS,Value="'`echo $itmpos`'"
                                    else
                                       [ "$itmpos" != "None" ] && [ "$vtmpos" == "None" ]
                                        aws ec2 create-tags --resources $volume --tags Key=OS,Value=`echo $itmpos`
                                    fi

# Evaluation of Instance Tag OWNER v Volume Tag OWNER
                                    if [ $dryrun = "yes" ]; then
                                       [ "$itmpown" != "None" ] && [ "$vtmpown" == "None" ]
                                        aws ec2 create-tags --dry-run --resources $volume --tags Key=Owner,Value="'`echo $itmpown`'"
                                    else
                                       [ "$tmpown" != "None" ] && [ "$vtmpown" == "None" ]
                                        aws ec2 create-tags --resources $volume --tags Key=Owner,Value=`echo $itmpown`
                                    fi

# Evaluation of Instance Tag PROJECT v Volume Tag PROJECT
                                    if [ $dryrun = "yes" ]; then
                                       [ "$itmpproj" != "None" ] && [ "$vtmpproj" == "None" ]
                                        aws ec2 create-tags --dry-run --resources $volume --tags Key=Project,Value="'`echo $itmpproj`'"
                                    else
                                       [ "$itmpproj" != "None" ] && [ "$vtmpproj" == "None" ]
                                        aws ec2 create-tags --resources $volume --tags Key=Project,Value=`echo $itmpproj`
                                    fi

# Evaluation of Instance Tag RELEASE v Volume Tag RELEASE
                                    if [ $dryrun = "yes" ]; then
                                       [ "$itmprel" != "None" ] && [ "$vtmprel" == "None" ]
                                        aws ec2 create-tags --dry-run --resources $volume --tags Key=Release,Value="'`echo $itmprel`'"
                                    else
                                       [ "$itmprel" != "None" ] && [ "$vtmprel" == "None" ]
                                        aws ec2 create-tags --resources $volume --tags Key=Release,Value=`echo $itmprel`
                                    fi

# Evaluation of Instance Tag ROLE v Volume Tag ROLE
                                    if [ $dryrun = "yes" ]; then
                                       [ "$itmprol" != "None" ] && [ "$tmprol" == "None" ]
                                        aws ec2 create-tags --dry-run --resources $volume --tags Key=Role,Value="'`echo $itmprol`'"
                                    else
                                       [ "$itmprol" != "None" ] && [ "$vtmprol" == "None" ]
                                    aws ec2 create-tags --resources $volume --tags Key=Role,Value=`echo $itmprol`
                                    fi


# Evaluation of Instance Tag ATTACHMENT v Volume Tag ATTACHMENT
                                    if [ $dryrun = "yes" ]; then
                                       [ "$itmpatt" != "None" ] && [ "$vtmpatt" == "None" ]
                                        aws ec2 create-tags --dry-run --resources $volume --tags Key=Attachment,Value="'`echo $dAttachment`'"
                                    else
 	                                    [ "$itmpatt" != "None" ] && [ "$vtmpatt" == "None" ]
	                                     aws ec2 create-tags --resources $volume --tags Key=Attachment,Value=`echo $dAttachment`
                                    fi
# Evaluation of Instance Tag ATTACHMENT v Volume Tag ATTACHMENT
                                    if [ $dryrun = "yes" ]; then
                                       [ "$itmpatt" == "None" ] && [ "$vtmpatt" == "None" ]
                                        aws ec2 create-tags --dry-run --resources $volume --tags Key=Attachment,Value="'`echo $dAttachment`'"
                                    else
                                       [ "$itmpatt" == "None" ] && [ "$vtmpatt" == "None" ]
                                        aws ec2 create-tags --resources $volume --tags Key=Attachment,Value=`echo $dAttachment`
                                    fi

    done
done
echo Script has completed succesfully all Volume IDs are all up to date with Tag Attachment to correct instance
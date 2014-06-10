//
//  PFLoginViewController.m
//  PostFacebook
//
//  Created by Cesar Navarro on 12/29/13.
//  Copyright (c) 2013 Cesar Navarro. All rights reserved.
//

#import "PFLoginViewController.h"

@interface PFLoginViewController ()
@property (strong, nonatomic) IBOutlet FBProfilePictureView *profilePictureView;
@property (strong, nonatomic) IBOutlet UILabel *nameLabel;
@property (strong, nonatomic) IBOutlet UILabel *statusLabel;
@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet UIImageView *filterImageView;
@property (strong, nonatomic) IBOutlet UIView *fbLoginButtonView;
@property (strong, nonatomic) IBOutlet UITextField *message;
@end

@implementation PFLoginViewController

- (void) viewDidLoad
{
    [super viewDidLoad];
    [FBProfilePictureView class];
    FBLoginView *loginView = [[FBLoginView alloc] initWithReadPermissions:@[@"basic_info", @"email", @"user_likes"]];
    loginView.delegate = self;
    loginView.frame = CGRectMake(0, 0, self.fbLoginButtonView.frame.size.width, self.fbLoginButtonView.frame.size.height);
    [self.fbLoginButtonView addSubview:loginView];
}

#pragma mark - Button Actions

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
}

- (IBAction)selectImage:(id)sender
{
    [self.view endEditing:YES];
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:picker animated:YES completion:nil];
}

- (IBAction)postImage:(id)sender {
    [self postImageToFacebook:self.filterImageView.image];
}

#pragma mark - Miscellaneous

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *selectedImage = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
    [self.imageView setImage: selectedImage];
    [self blurImage:selectedImage];
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (void)postImageToFacebook:(UIImage *)image{
    NSData* imageData = UIImageJPEGRepresentation(image, 90);
    NSString *message = self.message.text;
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:message  , @"message", imageData, @"source", nil];
    [FBRequestConnection startWithGraphPath:@"me/photos" parameters:params HTTPMethod:@"POST" completionHandler:^(FBRequestConnection *connection, id result, NSError *error){
        [[[UIAlertView alloc] initWithTitle:@"Message"
                                    message:@"Image was posted"
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
        [self.message setText:@""];
        NSLog(@"Complete");
        NSLog(@"Connection: %@", connection);
        NSLog(@"Result: %@", result);
        NSLog(@"Error: %@ %@", error, [error userInfo]);
    }];
}

- (void)blurImage:(UIImage *)theImage
{
    //create our blurred image
    CIContext *context = [CIContext contextWithOptions:nil];
    CIImage *inputImage = [CIImage imageWithCGImage:theImage.CGImage];
    
    //setting up Gaussian Blur (we could use one of many filters offered by Core Image)
    CIFilter *filter = [CIFilter filterWithName:@"CIGaussianBlur"];
    [filter setValue:inputImage forKey:kCIInputImageKey];
    [filter setValue:[NSNumber numberWithFloat:5.0f] forKey:@"inputRadius"];
    CIImage *result = [filter valueForKey:kCIOutputImageKey];
    //CIGaussianBlur has a tendency to shrink the image a little, this ensures it matches up exactly to the bounds of our original image
    CGImageRef cgImage = [context createCGImage:result fromRect:[inputImage extent]];
    
    //add our blurred image to the scrollview
    self.filterImageView.image = [UIImage imageWithCGImage:cgImage];
}

#pragma mark - Facebook delegates

- (void)loginViewFetchedUserInfo:(FBLoginView *)loginView
                            user:(id<FBGraphUser>)user {
    self.profilePictureView.profileID = user.id;
    self.nameLabel.text = user.name;
}

- (void)loginViewShowingLoggedInUser:(FBLoginView *)loginView {
    self.statusLabel.text = @"You're logged in as";
}

- (void)loginViewShowingLoggedOutUser:(FBLoginView *)loginView {
    self.profilePictureView.profileID = nil;
    self.nameLabel.text = @"";
    self.statusLabel.text= @"You're not logged in!";
}

- (void)loginView:(FBLoginView *)loginView handleError:(NSError *)error {
    NSString *alertMessage, *alertTitle;
    if ([FBErrorUtility shouldNotifyUserForError:error]) {
        alertTitle = @"Facebook error";
        alertMessage = [FBErrorUtility userMessageForError:error];
    } else if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryAuthenticationReopenSession) {
        alertTitle = @"Session Error";
        alertMessage = @"Your current session is no longer valid. Please log in again.";
    } else if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryUserCancelled) {
        NSLog(@"user cancelled login");
    } else {
        alertTitle  = @"Something went wrong";
        alertMessage = @"Please try again later.";
        NSLog(@"Unexpected error:%@", error);
    }
    if (alertMessage) {
        [[[UIAlertView alloc] initWithTitle:alertTitle
                                    message:alertMessage
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
    }
}

@end
